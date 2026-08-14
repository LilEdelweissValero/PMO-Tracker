import { chromium } from "playwright";
import { resolve } from "node:path";

const root = resolve(import.meta.dirname, "../..");
const output = resolve(root, "docs/design");
const base = "http://127.0.0.1:3000";

async function inspectPage(page, path, screenshot, requiredText) {
  const consoleErrors = [];
  const pageErrors = [];
  const badResponses = [];
  page.on("console", (message) => {
    if (message.type() === "error") consoleErrors.push(message.text());
  });
  page.on("pageerror", (error) => pageErrors.push(String(error)));
  page.on("response", (response) => {
    if (response.status() >= 400) {
      badResponses.push({ status: response.status(), url: response.url() });
    }
  });

  await page.goto(`${base}${path}`);
  await page.waitForLoadState("networkidle");
  for (const text of requiredText) {
    await page
      .getByText(text, { exact: false })
      .first()
      .waitFor({ state: "visible" });
  }

  const overflowPx = await page.evaluate(
    () =>
      document.documentElement.scrollWidth -
      document.documentElement.clientWidth,
  );
  const assets = await page.evaluate(() =>
    [...document.images]
      .filter(
        (image) =>
          image.src.includes("/assets/") || image.src.includes("%2Fassets%2F"),
      )
      .map((image) => ({
        src: image.src,
        loaded: image.complete && image.naturalWidth > 0,
      })),
  );
  await page.screenshot({ path: resolve(output, screenshot), fullPage: true });

  return {
    path,
    url: page.url(),
    overflowPx,
    assets,
    consoleErrors,
    pageErrors,
    badResponses,
  };
}

const browser = await chromium.launch({ headless: true });
const desktop = await browser.newPage({
  viewport: { width: 1440, height: 1000 },
});
const mobile = await browser.newPage({ viewport: { width: 390, height: 844 } });

const results = [
  await inspectPage(
    desktop,
    "/dashboard",
    "dashboard-desktop-implemented.png",
    ["Good morning", "The Ball", "Latest Progress", "Latest Bumps"],
  ),
  await inspectPage(mobile, "/dashboard", "dashboard-mobile-implemented.png", [
    "Good morning",
    "The Ball",
    "Latest Progress",
    "Latest Bumps",
  ]),
  await inspectPage(
    desktop,
    "/projects/DEMO-021",
    "project-detail-implemented.png",
    ["Records search upgrade", "Ball with", "Timeline"],
  ),
  await inspectPage(mobile, "/login", "login-mobile-implemented.png", [
    "Welcome back",
    "Sign in",
  ]),
  await inspectPage(desktop, "/ball", "ball-view-implemented.png", [
    "Ball View",
    "PMO",
    "Developers",
    "System Owner",
  ]),
  await inspectPage(
    mobile,
    "/projects/new",
    "create-project-mobile-implemented.png",
    ["Create a Project", "Project Code", "Initial Ball Owner"],
  ),
  await inspectPage(desktop, "/reports/as-of", "as-of-report-implemented.png", [
    "As-of report",
    "Ball Owner",
  ]),
];

await browser.close();
console.log(JSON.stringify(results, null, 2));
