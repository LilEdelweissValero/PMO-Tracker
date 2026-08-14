export function safeReturnPath(value: FormDataEntryValue | string | null) {
  if (
    typeof value !== "string" ||
    !value.startsWith("/") ||
    value.startsWith("//")
  ) {
    return "/dashboard";
  }
  try {
    const url = new URL(value, "https://pmo.local");
    return url.origin === "https://pmo.local"
      ? `${url.pathname}${url.search}${url.hash}`
      : "/dashboard";
  } catch {
    return "/dashboard";
  }
}
