// Resolve the parent resource name so NUI callbacks always route correctly,
// falling back to the original hardcoded name used by the legacy UI.
export const resourceName: string = (() => {
  const fn = (window as unknown as { GetParentResourceName?: () => string })
    .GetParentResourceName;
  if (typeof fn === 'function') {
    try {
      return fn();
    } catch {
      /* ignore */
    }
  }
  return 'lunar_garage';
})();

/** POST a JSON payload to a FiveM NUI callback. No-ops gracefully in a browser. */
export async function fetchNui<T = unknown>(
  event: string,
  data: unknown = {},
): Promise<T | null> {
  try {
    const resp = await fetch(`https://${resourceName}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    return (await resp.json().catch(() => null)) as T | null;
  } catch {
    return null;
  }
}

export const isBrowser = !(window as unknown as { invokeNative?: unknown })
  .invokeNative;
