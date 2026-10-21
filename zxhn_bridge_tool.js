/*
 * ZXHN Z503 one-click bridge wizard prototype.
 *
 * Usage:
 *   node zxhn_bridge_tool.js --password <admin-password> [--ssid2g NAME]
 *     [--ssid5g NAME] [--wifi-pass PASSWORD] [--apply]
 *
 * Without --apply it stops at the confirmation page and changes nothing.
 */
const { chromium } = require("playwright-core");
const fs = require("fs");
const path = require("path");

const EDGE =
  [
    process.env.EDGE_PATH,
    "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
    "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe",
  ].find((candidate) => candidate && fs.existsSync(candidate));
const OUT = path.join(__dirname, "zxhn_shots");

function arg(name, fallback = "") {
  const index = process.argv.indexOf(`--${name}`);
  return index >= 0 ? process.argv[index + 1] || fallback : fallback;
}

const options = {
  router: arg("router", "192.168.10.1"),
  user: arg("user", "user"),
  password: arg("password", process.env.ZXHN_PASSWORD || ""),
  ssid2g: arg("ssid2g", process.env.ZXHN_SSID2G || ""),
  ssid5g: arg("ssid5g", process.env.ZXHN_SSID5G || ""),
  wifiPassword: arg("wifi-pass", process.env.ZXHN_WIFI_PASS || ""),
  apply: process.argv.includes("--apply"),
};

async function screenshot(page, name) {
  fs.mkdirSync(OUT, { recursive: true });
  await page.screenshot({
    path: path.join(OUT, `${name}.png`),
    fullPage: true,
  });
}

async function clearMasks(page) {
  await page.evaluate(() => {
    const selectors = [
      "#blackMask",
      "#mask",
      ".black_overlay",
      ".black_overlay_basic",
    ];
    for (const selector of selectors) {
      document.querySelectorAll(selector).forEach((element) => {
        element.style.display = "none";
        element.style.pointerEvents = "none";
      });
    }
  });
}

async function jsClick(page, selector) {
  await page.waitForSelector(selector, { timeout: 25000 });
  await clearMasks(page);
  await page.evaluate((target) => {
    const elements = Array.from(document.querySelectorAll(target)).filter((element) => {
      const style = window.getComputedStyle(element);
      return (
        style.display !== "none" &&
        style.visibility !== "hidden" &&
        element.offsetParent !== null
      );
    });
    if (!elements.length) throw new Error(`Visible element not found: ${target}`);
    elements[elements.length - 1].click();
  }, selector);
}

async function main() {
  if (!EDGE) {
    throw new Error("未找到 Microsoft Edge，请先安装 Edge 后重试。");
  }
  if (!options.password) {
    console.error("Missing --password (or ZXHN_PASSWORD).");
    process.exit(2);
  }
  const browser = await chromium.launch({
    executablePath: EDGE,
    headless: true,
    args: ["--disable-gpu", "--no-first-run"],
  });
  const context = await browser.newContext({ ignoreHTTPSErrors: true });
  const page = await context.newPage();
  page.setDefaultTimeout(45000);

  try {
    await page.goto(`http://${options.router}/`, {
      waitUntil: "domcontentloaded",
      timeout: 45000,
    });
    console.log("PROGRESS:正在登录路由器...");
    await page.fill("#Frm_Username", options.user);
    await page.fill("#Frm_Password", options.password);
    await page.click("#LoginId");
    await page.waitForSelector("#link2Guide", { timeout: 25000 });
    await page.waitForTimeout(1000);
    await clearMasks(page);
    console.log("PROGRESS:登录成功，正在打开配置向导...");
    await screenshot(page, "01_logged_in");

    await jsClick(page, "#link2Guide");
    await page.waitForSelector("#WANTYPE_Bridge", { timeout: 25000 });
    await clearMasks(page);
    await page.check("#WANTYPE_Bridge", { force: true });
    console.log("PROGRESS:已选择桥接（Bridge），正在进入下一步...");
    await screenshot(page, "02_bridge_selected");

    await jsClick(page, '#wizardSubmitArea input.wizardBtn[value="下一步"]');
    await page.waitForSelector("#ESSID_2G", { timeout: 25000 });
    await clearMasks(page);
    await page.waitForTimeout(1000);
    console.log("PROGRESS:正在设置 Wi-Fi 参数...");

    if (options.ssid2g) await page.fill("#ESSID_2G", options.ssid2g);
    if (options.ssid5g) await page.fill("#ESSID_5G", options.ssid5g);
    if (options.wifiPassword) {
      for (const name of ["KeyPassphrase_2G", "KeyPassphrase_5G"]) {
        await page.locator(`input[name="${name}"]`).evaluateAll(
          (elements, value) => {
            for (const element of elements) {
              element.value = value;
              element.dispatchEvent(new Event("input", { bubbles: true }));
              element.dispatchEvent(new Event("change", { bubbles: true }));
            }
          },
          options.wifiPassword
        );
      }
    }
    await screenshot(page, "03_wifi");

    await jsClick(page, '#wizardSubmitArea input.wizardBtn[value="下一步"]');
    await page.waitForTimeout(2000);
    await screenshot(page, "04_after_wifi_next");
    fs.writeFileSync(
      path.join(OUT, "04_after_wifi_next.html"),
      await page.content(),
      "utf-8"
    );
    const buttonInfo = await page.evaluate(() =>
      Array.from(document.querySelectorAll("#wizardSubmitArea input.wizardBtn")).map((element) => ({
        id: element.id,
        value: element.value,
        visible: element.offsetParent !== null,
        disabled: element.disabled,
      }))
    );
    console.log("WIZARD_BUTTONS", JSON.stringify(buttonInfo));
    const pageText = await page.evaluate(() => document.body.innerText);
    console.log("PAGE_TEXT", pageText.slice(-1200));

    // Some label-default Wi-Fi passwords contain no special character.
    // The Wi-Fi step asks for confirmation before accepting a weak password.
    await page.waitForTimeout(800);
    if (await page.locator("#confirmOK").isVisible().catch(() => false)) {
      console.log("PROGRESS:正在确认弱密码提示...");
      await screenshot(page, "04_weak_password_confirm");
      await page.evaluate(() => {
        const button = document.querySelector("#confirmOK");
        if (button) button.click();
      });
      await page.waitForTimeout(1000);
    }
    const onConfirmationPage = await page.evaluate(() =>
      document.body.innerText.includes("配置信息已经填写完毕")
    );
    if (!onConfirmationPage) {
      const fallback = await page.evaluate(() => {
        const setValue = (id, value) => {
          const element = document.getElementById(id);
          if (element) element.value = value;
        };
        const ssid2g = document.getElementById("ESSID_2G");
        const ssid5g = document.getElementById("ESSID_5G");
        const pass2g = document.querySelector(
          'input.passInvisible[name="KeyPassphrase_2G"]'
        );
        const pass5g = document.querySelector(
          'input.passInvisible[name="KeyPassphrase_5G"]'
        );
        setValue("WanMode", "bridge");
        setValue("OldWanMode", "DHCP");
        setValue("ISModeChange", "1");
        setValue("ETHBRIDGE_IACTION", "apply");
        setValue("WANCName", "Bridge");
        setValue("ETHBRIDGE_WANCName", "Bridge");
        setValue("WLANCFG_ESSID1", ssid2g ? ssid2g.value : "");
        setValue("WLANCFG_IACTION1", "apply");
        setValue("WLANPSK_KeyPassphrase1", pass2g ? pass2g.value : "");
        setValue("WLANPSK_IACTION1", "apply");
        setValue("WLANCFG_ESSID5", ssid5g ? ssid5g.value : "");
        setValue("WLANCFG_IACTION5", "apply");
        setValue("WLANPSK_KeyPassphrase5", pass5g ? pass5g.value : "");
        setValue("WLANPSK_IACTION5", "apply");
        if (typeof LoadPageLocally === "function") {
          LoadPageLocally("wizard_over_t.lp");
          return "navigated";
        }
        return "LoadPageLocally missing";
      });
      console.log("FALLBACK", fallback);
      await page.waitForTimeout(1200);
    }
    try {
      await page.waitForFunction(
        () => document.body.innerText.includes("配置信息已经填写完毕"),
        { timeout: 25000 }
      );
    } catch (error) {
      await screenshot(page, "04_wait_failed");
      fs.writeFileSync(
        path.join(OUT, "04_wait_failed.html"),
        await page.content(),
        "utf-8"
      );
      console.log("WAIT_TEXT", (await page.evaluate(() => document.body.innerText)).slice(-1600));
      throw error;
    }
    console.log("PROGRESS:参数已确认，准备应用桥接...");
    await screenshot(page, "04_confirmation");

    if (!options.apply) {
      console.log(
        "DRY_RUN_OK: reached confirmation page. Not clicking 完成."
      );
      return;
    }

    const finishButton = page.locator(
      '#wizardSubmitArea input.wizardBtn[value="完成"]'
    );
    if (await finishButton.isVisible().catch(() => false)) {
      await jsClick(page, '#wizardSubmitArea input.wizardBtn[value="完成"]');
    } else {
      console.log("PROGRESS:正在调用向导完成动作...");
      await page.evaluate(() => {
        if (typeof pageFinish === "function") {
          pageFinish();
        } else if (typeof changeWanMode === "function") {
          changeWanMode();
        } else {
          throw new Error("pageFinish/changeWanMode 不存在");
        }
      });
    }

    // Changing to/from bridge shows a second confirmation dialog when the
    // WAN port is Up.  The wizard does not submit until this is clicked.
    await page.waitForTimeout(1500);
    const finalConfirm = page.locator("#confirmOK");
    if (await finalConfirm.isVisible().catch(() => false)) {
      console.log("clicking final bridge confirmation");
      console.log("PROGRESS:正在确认切换桥接模式...");
      await jsClick(page, "#confirmOK");
    }
    console.log("PROGRESS:正在应用配置并等待路由器重启...");
    await page.waitForTimeout(10000);
    try {
      await screenshot(page, "05_applied");
    } catch {
      // The router often drops Wi-Fi / reboots after applying bridge mode.
    }
    console.log("APPLIED: bridge wizard submitted; router may reboot.");
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error("FAILED:", error.message);
  process.exit(1);
});
