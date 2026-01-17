// ==========================
// Constants
// ==========================
const SELECTORS = {
  COURSE: ".module__short-name",
  MODULE: ".context_module[aria-label*=Week]",
  ITEM: ".with-completion-requirements",
  TITLE: ".module-item-title",
  SCHEDULE_ITEM: ".ig-info:has(.points_possible_display) .module-item-title",
  DETAILS: ".ig-details",
  COLLAPSED_MODULE: "#context_modules .collapsed_module",
};

// ==========================
// DOM Utilities
// ==========================
const queryText = (selector, base = document) =>
  base.querySelector(selector)?.textContent.trim() || "";

const querySelectorAllAsArray = (selector, base = document) =>
  Array.from(base.querySelectorAll(selector));

const firstLine = (text) => text.split("\n")[0];

const scrollToTop = () =>
  window.scrollTo({ top: 0, left: 0, behavior: "smooth" });

const writeToClipboard = (text) => navigator.clipboard.writeText(text);

// ==========================
// Course & Module Info
// ==========================
function getCourseCode() {
  const raw = queryText(SELECTORS.COURSE);
  const base = raw.split("_")[0];
  return base.split(/(?<=\D+)(?=\d+)/).join(" ");
}

function getWeekNumber(moduleEl) {
  const header = moduleEl.getAttribute("aria-label") || "";
  const match = [...header.matchAll(/(Module|Week) (\d+)/g)];
  const weekMap = new Map(match.map((m) => m.slice(1, 3)));
  return Number(weekMap.get("Week")) - 1;
}

// ==========================
// Assignment Parsing
// ==========================
function parseDueDate(itemEl) {
  let raw = firstLine(queryText(SELECTORS.DETAILS, itemEl));
  if (!/\b\d{4}\b/.test(raw)) {
    const currentYear = new Date().getFullYear();
    raw += ` ${currentYear}`;
  }
  const date = new Date(Date.parse(raw));
  return isNaN(date) ? "" : date.toISOString().split("T")[0];
}

function formatTitle(itemEl) {
  const title = firstLine(queryText(SELECTORS.TITLE, itemEl));
  return title.replace(/ Assignment$/, "");
}

function getAssignments() {
  const courseCode = getCourseCode();
  const modules = querySelectorAllAsArray(SELECTORS.MODULE);

  return modules.flatMap((moduleEl) => {
    const week = getWeekNumber(moduleEl);
    const items = querySelectorAllAsArray(SELECTORS.ITEM, moduleEl);
    const entries = items.map((el) => [parseDueDate(el), formatTitle(el)]);

    return entries.map(([due, title], _, all) => {
      const fallbackDate = all.map(([d]) => d).find((d) => d) || "";
      return `${courseCode}\t${week}\t\t${due || fallbackDate}\t\t${title}`;
    });
  });
}

// ==========================
// Schedule Parsing
// ==========================
function getScheduleAssignments(moduleEl) {
  return querySelectorAllAsArray(SELECTORS.SCHEDULE_ITEM, moduleEl)
    .map((el) => firstLine(el.textContent.trim()))
    .filter((t) => !/Watch:/.test(t))
    .map((t) => t.split(":")[0])
    .join(", ");
}

function getSchedule() {
  return querySelectorAllAsArray(SELECTORS.MODULE).map((moduleEl) => {
    const week = getWeekNumber(moduleEl);
    const topic = moduleEl.getAttribute("aria-label").split(/\s-\s|\n/)[1];
    // const assignments = getScheduleAssignments(moduleEl);
    return [week, topic].join("\t");
  });
}

// ==========================
// Expand & Copy Actions
// ==========================
function expandAllModules() {
  querySelectorAllAsArray(SELECTORS.COLLAPSED_MODULE).forEach((module) => {
    module.querySelector(".collapse_module_link")?.click();
  });
}

function handleCopy(callback) {
  expandAllModules();
  const text = callback().join("\n");
  writeToClipboard(text);
  console.log(text);
  setInterval(scrollToTop, 1000);
}

function parseSchedule() {
  handleCopy(getSchedule);
}

function parseAssignments() {
  handleCopy(getAssignments);
}

// ==========================
// UI Setup
// ==========================
function injectButtons() {
  const html = `
    <button id="copy-schedule" type="button"><span class="cds-button-label">Copy Schedule</span></button>
    <button id="copy-assignments" type="button"><span class="cds-button-label">Copy Assignments</span></button>
  `;
  document.querySelector("h1")?.insertAdjacentHTML("afterEnd", html);
  document.getElementById("copy-schedule")?.addEventListener("click", parseSchedule);
  document.getElementById("copy-assignments")?.addEventListener("click", parseAssignments);
}

injectButtons();
