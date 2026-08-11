// Diagonal + cross-hatch canvas patterns used to fill weekend/holiday bars so
// day type is legible without relying on color alone (accessibility). Ported
// verbatim from the original viewer.

export function createDiagonalPattern(
  fgColor: string,
  bgColor: string,
  spacing: number
): HTMLCanvasElement {
  const c = document.createElement("canvas");
  c.width = spacing;
  c.height = spacing;
  const ctx = c.getContext("2d")!;
  ctx.fillStyle = bgColor;
  ctx.fillRect(0, 0, spacing, spacing);
  ctx.strokeStyle = fgColor;
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(0, spacing);
  ctx.lineTo(spacing, 0);
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(-spacing / 2, spacing / 2);
  ctx.lineTo(spacing / 2, -spacing / 2);
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(spacing / 2, spacing * 1.5);
  ctx.lineTo(spacing * 1.5, spacing / 2);
  ctx.stroke();
  return c;
}

export function createCrossHatchPattern(
  fgColor: string,
  bgColor: string,
  spacing: number
): HTMLCanvasElement {
  const c = document.createElement("canvas");
  c.width = spacing;
  c.height = spacing;
  const ctx = c.getContext("2d")!;
  ctx.fillStyle = bgColor;
  ctx.fillRect(0, 0, spacing, spacing);
  ctx.strokeStyle = fgColor;
  ctx.lineWidth = 1.5;
  // one diagonal
  ctx.beginPath(); ctx.moveTo(0, spacing); ctx.lineTo(spacing, 0); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(-spacing / 2, spacing / 2); ctx.lineTo(spacing / 2, -spacing / 2); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(spacing / 2, spacing * 1.5); ctx.lineTo(spacing * 1.5, spacing / 2); ctx.stroke();
  // the other diagonal
  ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(spacing, spacing); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(-spacing / 2, spacing / 2); ctx.lineTo(spacing / 2, spacing * 1.5); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(spacing / 2, -spacing / 2); ctx.lineTo(spacing * 1.5, spacing / 2); ctx.stroke();
  return c;
}

export interface DayPatterns {
  weekend: CanvasPattern | null;
  holiday: CanvasPattern | null;
}

export function buildDayPatterns(ctx: CanvasRenderingContext2D): DayPatterns {
  return {
    weekend: ctx.createPattern(createDiagonalPattern("#5b8def", "#1e3a6b", 8), "repeat"),
    holiday: ctx.createPattern(createCrossHatchPattern("#f59e0b", "#3b2008", 8), "repeat"),
  };
}
