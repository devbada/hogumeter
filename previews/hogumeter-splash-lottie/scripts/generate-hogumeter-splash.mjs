import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const appAnimationPath = resolve(
  root,
  "../../HoguMeter/Resources/Animations/HoguMeterSplash.json"
);

const C = {
  orange: [0.839, 0.353, 0.196, 1],
  yellow: [1, 0.71, 0.08, 1],
  yellowDark: [0.89, 0.49, 0.015, 1],
  blue: [0.055, 0.34, 0.58, 1],
  dark: [0.045, 0.055, 0.06, 1],
  charcoal: [0.09, 0.11, 0.12, 1],
  gray: [0.33, 0.35, 0.35, 1],
  lightGray: [0.78, 0.8, 0.79, 1],
  white: [1, 1, 1, 1],
  horse: [0.42, 0.29, 0.21, 1],
  muzzle: [0.91, 0.82, 0.67, 1],
  mane: [0.19, 0.12, 0.09, 1],
  green: [0.32, 1, 0.34, 1],
  sweat: [0.28, 0.78, 1, 1],
};

const easeIn = { x: [0.55], y: [1] };
const easeOut = { x: [0.45], y: [0] };

function staticValue(value) {
  return { a: 0, k: value };
}

function animatedValue(keyframes) {
  return { a: 1, k: keyframes };
}

function keyframe(t, s, easing = true) {
  return easing
    ? { t, s, i: easeIn, o: easeOut }
    : { t, s };
}

function transform({
  opacity = 100,
  rotation = 0,
  position = [0, 0, 0],
  anchor = [0, 0, 0],
  scale = [100, 100, 100],
} = {}) {
  return {
    o: typeof opacity === "number" ? staticValue(opacity) : opacity,
    r: typeof rotation === "number" ? staticValue(rotation) : rotation,
    p: Array.isArray(position) ? staticValue(position) : position,
    a: staticValue(anchor),
    s: Array.isArray(scale) ? staticValue(scale) : scale,
  };
}

function groupTransform({
  opacity = 100,
  rotation = 0,
  position = [0, 0],
  anchor = [0, 0],
  scale = [100, 100],
} = {}) {
  return {
    ty: "tr",
    p: Array.isArray(position) ? staticValue(position) : position,
    a: staticValue(anchor),
    s: Array.isArray(scale) ? staticValue(scale) : scale,
    r: typeof rotation === "number" ? staticValue(rotation) : rotation,
    o: typeof opacity === "number" ? staticValue(opacity) : opacity,
  };
}

function fill(color) {
  return {
    ty: "fl",
    c: typeof color === "string" ? { sid: color } : staticValue(color),
    o: staticValue(100),
  };
}

function stroke(color, width) {
  return {
    ty: "st",
    c: staticValue(color),
    o: staticValue(100),
    w: staticValue(width),
    lc: 2,
    lj: 2,
  };
}

function rectGroup(name, position, size, radius, color, options = {}) {
  return {
    ty: "gr",
    nm: name,
    it: [
      {
        ty: "rc",
        p: staticValue(position),
        s: staticValue(size),
        r: staticValue(radius),
      },
      fill(color),
      groupTransform(options),
    ],
  };
}

function ellipseGroup(name, position, size, color, options = {}) {
  return {
    ty: "gr",
    nm: name,
    it: [
      { ty: "el", p: staticValue(position), s: staticValue(size) },
      fill(color),
      groupTransform(options),
    ],
  };
}

function pathGroup(name, vertices, color, { closed = true, strokeColor, strokeWidth = 0 } = {}) {
  const tangents = vertices.map(() => [0, 0]);
  const items = [
    {
      ty: "sh",
      ks: staticValue({
        c: closed,
        v: vertices,
        i: tangents,
        o: tangents,
      }),
    },
  ];

  if (color) items.push(fill(color));
  if (strokeColor && strokeWidth) items.push(stroke(strokeColor, strokeWidth));
  items.push(groupTransform());

  return { ty: "gr", nm: name, it: items };
}

function shapeLayer(name, shapes, ks = transform(), ip = 0, op = 180) {
  return {
    ty: 4,
    nm: name,
    ip,
    op,
    st: 0,
    ks,
    shapes,
  };
}

const taxiPosition = animatedValue([
  keyframe(0, [-170, 425, 0]),
  keyframe(12, [-120, 419, 0]),
  keyframe(64, [195, 425, 0]),
  keyframe(79, [203, 411, 0]),
  keyframe(94, [195, 425, 0]),
  keyframe(120, [195, 419, 0]),
  keyframe(145, [195, 425, 0]),
  keyframe(156, [215, 417, 0]),
  keyframe(180, [570, 415, 0], false),
]);

const taxiRotation = animatedValue([
  keyframe(0, [-2]),
  keyframe(64, [0]),
  keyframe(79, [2]),
  keyframe(94, [0]),
  keyframe(145, [0]),
  keyframe(156, [-2]),
  keyframe(180, [0], false),
]);

function taxiTransform(extra = {}) {
  return transform({
    position: taxiPosition,
    rotation: taxiRotation,
    scale: [92, 92, 100],
    ...extra,
  });
}

const wheelRotation = animatedValue([
  keyframe(0, [0]),
  keyframe(64, [720]),
  keyframe(145, [810]),
  keyframe(180, [1440], false),
]);

const segmentMap = {
  0: ["a", "b", "c", "d", "e", "f"],
  1: ["b", "c"],
  2: ["a", "b", "g", "e", "d"],
  3: ["a", "b", "c", "d", "g"],
  4: ["f", "g", "b", "c"],
  8: ["a", "b", "c", "d", "e", "f", "g"],
};

function digitGroups(digit, x, y, scale = 1) {
  const w = 12 * scale;
  const h = 20 * scale;
  const t = 2.4 * scale;
  const segments = {
    a: [x, y - h / 2, w, t],
    b: [x + w / 2, y - h / 4, t, h / 2],
    c: [x + w / 2, y + h / 4, t, h / 2],
    d: [x, y + h / 2, w, t],
    e: [x - w / 2, y + h / 4, t, h / 2],
    f: [x - w / 2, y - h / 4, t, h / 2],
    g: [x, y, w, t],
  };

  return segmentMap[digit].map((segment, index) => {
    const [sx, sy, sw, sh] = segments[segment];
    return rectGroup(`digit-${digit}-${segment}-${index}`, [sx, sy], [sw, sh], t / 2, C.green);
  });
}

const bitmapFont = {
  H: ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
  O: ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
  G: ["01110", "10001", "10000", "10111", "10001", "10001", "01110"],
  U: ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
  M: ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
  E: ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
  T: ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
  R: ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
};

function bitmapTextGroups(text, pixel = 4.2, gap = 1) {
  const groups = [];
  const charWidth = 5 * pixel;
  const totalWidth = text.length * charWidth + (text.length - 1) * gap * pixel;
  let cursor = -totalWidth / 2;

  for (const char of text) {
    const rows = bitmapFont[char];
    rows.forEach((row, rowIndex) => {
      [...row].forEach((cell, columnIndex) => {
        if (cell !== "1") return;
        groups.push(
          rectGroup(
            `title-${char}-${rowIndex}-${columnIndex}-${groups.length}`,
            [
              cursor + columnIndex * pixel + pixel / 2,
              rowIndex * pixel - 3 * pixel,
            ],
            [pixel * 0.8, pixel * 0.8],
            pixel * 0.2,
            C.white
          )
        );
      });
    });
    cursor += charWidth + gap * pixel;
  }

  return groups;
}

const titleOpacity = animatedValue([
  keyframe(0, [0]),
  keyframe(78, [0]),
  keyframe(108, [100]),
  keyframe(150, [100]),
  keyframe(174, [0], false),
]);

const titleScale = animatedValue([
  keyframe(0, [86, 86, 100]),
  keyframe(78, [86, 86, 100]),
  keyframe(108, [100, 100, 100]),
  keyframe(150, [100, 100, 100]),
  keyframe(174, [108, 108, 100], false),
]);

const layers = [
  shapeLayer(
    "hogu-reaction",
    [
      pathGroup(
        "question-mark-curve",
        [
          [-12, -10],
          [-12, -23],
          [0, -31],
          [13, -25],
          [15, -14],
          [4, -5],
          [1, 4],
        ],
        null,
        { closed: false, strokeColor: C.white, strokeWidth: 5 }
      ),
      ellipseGroup("question-mark-dot", [0, 17], [6, 6], C.white),
    ],
    transform({
      position: [319, 289, 0],
      opacity: animatedValue([
        keyframe(0, [0]),
        keyframe(92, [0]),
        keyframe(105, [100]),
        keyframe(135, [100]),
        keyframe(150, [0], false),
      ]),
      rotation: animatedValue([
        keyframe(0, [-10]),
        keyframe(92, [-10]),
        keyframe(112, [8]),
        keyframe(135, [-4]),
        keyframe(150, [12], false),
      ]),
      scale: animatedValue([
        keyframe(0, [40, 40, 100]),
        keyframe(92, [40, 40, 100]),
        keyframe(110, [120, 120, 100]),
        keyframe(122, [100, 100, 100]),
        keyframe(150, [80, 80, 100], false),
      ]),
    })
  ),
  shapeLayer(
    "hogu-sweat",
    [
      pathGroup("sweat-drop", [
        [0, -15],
        [-11, 2],
        [-8, 14],
        [0, 19],
        [8, 14],
        [11, 2],
      ], C.sweat),
      ellipseGroup("sweat-highlight", [-3, 5], [4, 8], [1, 1, 1, 0.7]),
    ],
    transform({
      position: animatedValue([
        keyframe(0, [280, 304, 0]),
        keyframe(98, [280, 304, 0]),
        keyframe(125, [292, 335, 0]),
        keyframe(150, [300, 355, 0], false),
      ]),
      opacity: animatedValue([
        keyframe(0, [0]),
        keyframe(98, [0]),
        keyframe(108, [100]),
        keyframe(138, [100]),
        keyframe(150, [0], false),
      ]),
    })
  ),
  shapeLayer(
    "brand-title",
    bitmapTextGroups("HOGUMETER"),
    transform({
      position: [195, 646, 0],
      opacity: titleOpacity,
      scale: titleScale,
    })
  ),
  shapeLayer(
    "brand-underline",
    [
      rectGroup("underline", [0, 0], [132, 6], 3, C.yellow),
      ellipseGroup("underline-dot-left", [-78, 0], [7, 7], C.white),
      ellipseGroup("underline-dot-right", [78, 0], [7, 7], C.white),
    ],
    transform({
      position: [195, 690, 0],
      opacity: titleOpacity,
      scale: titleScale,
    })
  ),
  shapeLayer(
    "sparkle-left",
    [
      rectGroup("sparkle-v", [0, 0], [5, 28], 2.5, C.white),
      rectGroup("sparkle-h", [0, 0], [28, 5], 2.5, C.white),
    ],
    transform({
      position: [58, 330, 0],
      rotation: animatedValue([
        keyframe(0, [0]),
        keyframe(85, [0]),
        keyframe(125, [90]),
        keyframe(160, [180], false),
      ]),
      opacity: animatedValue([
        keyframe(0, [0]),
        keyframe(88, [0]),
        keyframe(105, [100]),
        keyframe(145, [100]),
        keyframe(165, [0], false),
      ]),
      scale: animatedValue([
        keyframe(0, [30, 30, 100]),
        keyframe(88, [30, 30, 100]),
        keyframe(110, [100, 100, 100]),
        keyframe(145, [70, 70, 100]),
        keyframe(165, [30, 30, 100], false),
      ]),
    })
  ),
  shapeLayer(
    "sparkle-right",
    [
      rectGroup("sparkle-v", [0, 0], [4, 22], 2, C.yellow),
      rectGroup("sparkle-h", [0, 0], [22, 4], 2, C.yellow),
    ],
    transform({
      position: [331, 365, 0],
      rotation: animatedValue([
        keyframe(0, [0]),
        keyframe(95, [0]),
        keyframe(135, [-90]),
        keyframe(165, [-180], false),
      ]),
      opacity: animatedValue([
        keyframe(0, [0]),
        keyframe(98, [0]),
        keyframe(112, [100]),
        keyframe(145, [100]),
        keyframe(165, [0], false),
      ]),
    })
  ),
  shapeLayer(
    "horse-details",
    [
      ellipseGroup("eye-white", [18, -43], [13, 13], C.white),
      ellipseGroup("eye", [0, 0], [7, 7], C.dark, {
        position: animatedValue([
          keyframe(0, [20, -43]),
          keyframe(92, [20, -43]),
          keyframe(106, [24, -40]),
          keyframe(138, [24, -40]),
          keyframe(150, [20, -43], false),
        ]),
      }),
      pathGroup(
        "worried-eyebrow",
        [
          [12, -55],
          [20, -61],
          [29, -57],
        ],
        null,
        { closed: false, strokeColor: C.mane, strokeWidth: 3 }
      ),
      ellipseGroup("nostril", [45, -12], [5, 4], C.dark),
      ellipseGroup("surprised-mouth", [37, 3], [11, 14], C.dark),
      rectGroup("hat-brim", [0, -75], [73, 9], 4, C.dark),
      ellipseGroup("hat-top", [-5, -81], [59, 26], C.yellow),
      ...[
        [-19, -75],
        [-7, -75],
        [5, -75],
        [17, -75],
      ].map(([x, y], index) =>
        rectGroup(`hat-check-${index}`, [x, y], [7, 7], 0, index % 2 === 0 ? C.white : C.dark)
      ),
    ],
    taxiTransform()
  ),
  shapeLayer(
    "horse-base",
    [
      pathGroup("mane", [
        [-31, -64],
        [-43, -45],
        [-37, -16],
        [-25, 4],
        [-12, -3],
        [-18, -25],
        [-12, -51],
      ], C.mane),
      pathGroup("ear-left", [
        [-24, -65],
        [-21, -96],
        [-7, -69],
      ], C.horse),
      pathGroup("ear-right", [
        [-2, -69],
        [5, -99],
        [15, -68],
      ], C.horse),
      ellipseGroup("head", [5, -34], [75, 82], C.horse),
      ellipseGroup("muzzle", [34, -11], [55, 39], C.muzzle),
      rectGroup("neck", [-12, 4], [38, 50], 15, C.horse),
    ],
    taxiTransform()
  ),
  shapeLayer(
    "meter-digits",
    [
      ...digitGroups(1, 48, 7, 0.62),
      ...digitGroups(2, 62, 7, 0.62),
      ...digitGroups(3, 76, 7, 0.62),
      ...digitGroups(0, 90, 7, 0.62),
    ],
    taxiTransform({
      opacity: animatedValue([
        keyframe(0, [55]),
        keyframe(45, [100]),
        keyframe(90, [70]),
        keyframe(100, [100]),
        keyframe(180, [100], false),
      ]),
    })
  ),
  shapeLayer(
    "taxi-details",
    [
      rectGroup("roof-sign", [-8, -103], [122, 34], 8, "taxiColor"),
      rectGroup("sign-blue-left", [-40, -103], [13, 17], 2, C.blue),
      rectGroup("sign-blue-center", [-15, -103], [31, 7], 3, C.blue),
      rectGroup("sign-blue-right", [23, -103], [31, 7], 3, C.blue),
      rectGroup("meter-panel", [69, 7], [64, 28], 5, C.dark),
      ellipseGroup("headlight-left", [-113, 24], [31, 31], C.white),
      ellipseGroup("headlight-right", [113, 24], [31, 31], C.white),
      ellipseGroup("headlight-left-ring", [-113, 24], [38, 38], C.lightGray),
      ellipseGroup("headlight-right-ring", [113, 24], [38, 38], C.lightGray),
      rectGroup("bumper", [0, 66], [246, 19], 9, C.lightGray),
      rectGroup("bumper-left", [-88, 66], [15, 32], 7, C.gray),
      rectGroup("bumper-right", [88, 66], [15, 32], 7, C.gray),
      ellipseGroup("mirror-left", [-132, -3], [27, 22], C.yellowDark),
      ellipseGroup("mirror-right", [132, -3], [27, 22], C.yellowDark),
      pathGroup("door-horse", [
        [-65, 9],
        [-51, -8],
        [-35, 9],
        [-44, 32],
        [-65, 32],
      ], C.blue),
    ],
    taxiTransform()
  ),
  shapeLayer(
    "taxi-windows",
    [
      pathGroup("window-left", [
        [-78, -8],
        [-57, -69],
        [-10, -69],
        [-10, -8],
      ], C.charcoal),
      pathGroup("window-right", [
        [0, -69],
        [40, -69],
        [73, -8],
        [0, -8],
      ], C.charcoal),
      rectGroup("window-divider", [-5, -37], [9, 67], 3, C.yellowDark),
    ],
    taxiTransform()
  ),
  shapeLayer(
    "taxi-body",
    [
      pathGroup("cabin", [
        [-96, 9],
        [-64, -84],
        [43, -84],
        [88, 9],
      ], "taxiColor"),
      rectGroup("body", [0, 25], [270, 104], 32, "taxiColor"),
      rectGroup("hood", [80, -4], [115, 54], 22, C.yellowDark),
      rectGroup("lower-body", [0, 49], [250, 50], 22, C.yellowDark),
    ],
    taxiTransform()
  ),
  shapeLayer(
    "taxi-wheels",
    [
      ellipseGroup("wheel-left", [-82, 70], [67, 67], C.dark),
      ellipseGroup("wheel-right", [86, 70], [67, 67], C.dark),
      ellipseGroup("hub-left", [-82, 70], [31, 31], C.yellowDark),
      ellipseGroup("hub-right", [86, 70], [31, 31], C.yellowDark),
      rectGroup("hub-mark-left", [0, 0], [7, 25], 3, C.dark, {
        position: [-82, 70],
        rotation: wheelRotation,
      }),
      rectGroup("hub-mark-right", [0, 0], [7, 25], 3, C.dark, {
        position: [86, 70],
        rotation: wheelRotation,
      }),
    ],
    taxiTransform()
  ),
  shapeLayer(
    "taxi-shadow",
    [ellipseGroup("shadow", [0, 86], [260, 35], [0.2, 0.08, 0.02, 0.28])],
    taxiTransform({
      scale: animatedValue([
        keyframe(0, [88, 80, 100]),
        keyframe(79, [95, 70, 100]),
        keyframe(94, [92, 92, 100]),
        keyframe(180, [88, 80, 100], false),
      ]),
    })
  ),
  shapeLayer(
    "speed-lines",
    [
      rectGroup("line-1", [-20, -75], [135, 7], 3.5, C.white),
      rectGroup("line-2", [22, -35], [195, 5], 2.5, C.yellow),
      rectGroup("line-3", [-42, 7], [108, 6], 3, C.white),
      rectGroup("line-4", [32, 49], [165, 5], 2.5, C.yellow),
    ],
    transform({
      position: animatedValue([
        keyframe(0, [430, 425, 0]),
        keyframe(64, [-180, 425, 0]),
        keyframe(145, [430, 425, 0]),
        keyframe(180, [-180, 425, 0], false),
      ]),
      opacity: animatedValue([
        keyframe(0, [0]),
        keyframe(10, [80]),
        keyframe(64, [0]),
        keyframe(145, [0]),
        keyframe(156, [85]),
        keyframe(180, [0], false),
      ]),
    })
  ),
  ...[0, 1, 2].map((index) =>
    shapeLayer(
      `loading-dot-${index}`,
      [ellipseGroup(`dot-${index}`, [0, 0], [9, 9], index === 1 ? C.yellow : C.white)],
      transform({
        position: [177 + index * 18, 735, 0],
        opacity: animatedValue([
          keyframe(0, [25]),
          keyframe(20 + index * 8, [25]),
          keyframe(34 + index * 8, [100]),
          keyframe(48 + index * 8, [25]),
          keyframe(92 + index * 8, [25]),
          keyframe(106 + index * 8, [100]),
          keyframe(120 + index * 8, [25]),
          keyframe(180, [25], false),
        ]),
      })
    )
  ),
  shapeLayer(
    "background-panel",
    [rectGroup("panel", [0, 0], [340, 630], 48, [0.91, 0.459, 0.271, 0.38])],
    transform({ position: [195, 415, 0] })
  ),
  shapeLayer(
    "background",
    [rectGroup("background-fill", [0, 0], [390, 844], 0, "bgColor")],
    transform({ position: [195, 422, 0] })
  ),
];

const lottie = {
  v: "5.7.0",
  fr: 60,
  ip: 0,
  op: 180,
  w: 390,
  h: 844,
  nm: "HoguMeter Splash Preview",
  ddd: 0,
  assets: [],
  slots: {
    bgColor: { p: { a: 0, k: C.orange } },
    taxiColor: { p: { a: 0, k: C.yellow } },
  },
  layers,
};

const controls = {
  controls: [
    { sid: "bgColor", label: "배경색" },
    { sid: "taxiColor", label: "택시 색상" },
  ],
};

function resolveSlots(value, slots) {
  if (Array.isArray(value)) {
    return value.map((item) => resolveSlots(item, slots));
  }

  if (value && typeof value === "object") {
    if (typeof value.sid === "string") {
      return JSON.parse(JSON.stringify(slots[value.sid].p));
    }

    return Object.fromEntries(
      Object.entries(value)
        .filter(([key]) => key !== "slots")
        .map(([key, item]) => [key, resolveSlots(item, slots)])
    );
  }

  return value;
}

const iosLottie = resolveSlots(lottie, lottie.slots);

writeFileSync(resolve(root, "public/lottie.json"), `${JSON.stringify(lottie, null, 2)}\n`);
writeFileSync(resolve(root, "public/controls.json"), `${JSON.stringify(controls, null, 2)}\n`);
writeFileSync(appAnimationPath, `${JSON.stringify(iosLottie, null, 2)}\n`);

console.log(
  `Generated ${lottie.nm}: ${layers.length} layers, ${lottie.op / lottie.fr}s`
);
console.log(`Generated iOS resource: ${appAnimationPath}`);
