import { mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const appstoreDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const outputDir = resolve(appstoreDir, "marketing-6.9-1290x2796");
const actual65Dir = resolve(appstoreDir, "marketing-6.5-1284x2778");
const assetDir = resolve(outputDir, "assets");
const sourceDir = resolve(appstoreDir, "iPhone");
const magick = "/opt/homebrew/bin/magick";
const fontRegular = "/Library/Fonts/LG_Smart_UI-Regular.ttf";
const fontBold = "/Library/Fonts/LG_Smart_UI-Bold.ttf";

mkdirSync(outputDir, { recursive: true });
mkdirSync(actual65Dir, { recursive: true });
mkdirSync(assetDir, { recursive: true });

const run = (...args) => {
  const result = spawnSync(magick, args, { encoding: "utf8" });
  if (result.status !== 0) {
    throw new Error(result.stderr || result.stdout);
  }
};

const splashSource = resolve(assetDir, "00_splash.png");
const splashArtwork = resolve(
  appstoreDir,
  "../previews/hogumeter-splash-lottie/preview-frame-120.png"
);

run(
  "-size",
  "390x844",
  "xc:#D65A32",
  "(",
  splashArtwork,
  "-fuzz",
  "4%",
  "-fill",
  "#D65A32",
  "-opaque",
  "#F14803",
  "-fill",
  "#E87545",
  "-opaque",
  "#F56010",
  ")",
  "-gravity",
  "center",
  "-composite",
  splashSource
);

const screens = [
  {
    source: splashSource,
    output: "00_splash_marketing.png",
    eyebrow: "친구 · 동승자와 즐기는 재미용 미터",
    title: "같이 타면 더 재밌는\n주행 요금 놀이",
  },
  {
    source: resolve(sourceDir, "01_main_idle.png"),
    output: "01_main_idle_marketing.png",
    eyebrow: "이동 시간과 거리를 재미로 측정",
    title: "출발 버튼 한 번으로\n주행 놀이 시작",
  },
  {
    source: resolve(sourceDir, "02_running.png"),
    output: "02_running_marketing.png",
    eyebrow: "친구들과 보는 실시간 주행 정보",
    title: "달리는 순간마다\n숫자가 쑥쑥",
  },
  {
    source: resolve(sourceDir, "03_receipt.png"),
    output: "03_receipt_marketing.png",
    eyebrow: "재미로 만든 주행 결과 카드",
    title: "오늘의 드라이브를\n영수증처럼 간직",
  },
  {
    source: resolve(sourceDir, "04_settings.png"),
    output: "04_settings_marketing.png",
    eyebrow: "지역 · 야간 보너스 금액 설정",
    title: "우리끼리 정한 규칙도\n자유롭게 설정",
  },
  {
    source: resolve(sourceDir, "05_region_fares.png"),
    output: "05_region_fares_marketing.png",
    eyebrow: "친구들과 정한 지역별 놀이 요금",
    title: "지역마다 다른 설정을\n내 마음대로 저장",
  },
  {
    source: resolve(sourceDir, "06_history.png"),
    output: "06_history_marketing.png",
    eyebrow: "날짜별 재미 기록 보관",
    title: "지난 드라이브 추억\n한눈에 다시 보기",
  },
  {
    source: resolve(sourceDir, "07_map.png"),
    output: "07_map_marketing.png",
    eyebrow: "거리 · 시간 · 경로를 한 화면에",
    title: "함께 달린 경로를\n지도에서 다시 보기",
  },
  {
    source: resolve(sourceDir, "08_statistics.png"),
    output: "08_statistics_marketing.png",
    eyebrow: "월별 · 주간별 재미 기록 분석",
    title: "함께 달린 만큼\n통계로 한눈에",
  },
];

for (const [index, screen] of screens.entries()) {
  const clipped = resolve(assetDir, `screen-${index}.png`);
  const frame = resolve(assetDir, `frame-${index}.png`);
  const output = resolve(outputDir, screen.output);

  run(
    screen.source,
    "-resize",
    "900x1951!",
    "(",
    "-size",
    "900x1951",
    "xc:none",
    "-fill",
    "white",
    "-draw",
    "roundrectangle 0,0 899,1950 58,58",
    ")",
    "-alpha",
    "off",
    "-compose",
    "CopyOpacity",
    "-composite",
    clipped
  );

  run(
    "-size",
    "948x1999",
    "xc:none",
    "-fill",
    "white",
    "-draw",
    "roundrectangle 0,0 947,1998 78,78",
    clipped,
    "-geometry",
    "+24+24",
    "-compose",
    "over",
    "-composite",
    frame
  );

  run(
    "-size",
    "1290x2796",
    "xc:#FFF9F3",
    "-fill",
    "rgba(214,90,50,0.10)",
    "-draw",
    "ellipse 1235,30 330,330 0,360",
    "-fill",
    "rgba(255,181,26,0.10)",
    "-draw",
    "ellipse 10,2670 270,270 0,360",
    "-fill",
    "#2A1813",
    "-draw",
    "roundrectangle 80,88 388,170 41,41",
    "-fill",
    "#FFB51A",
    "-draw",
    "circle 119,129 119,112",
    "-font",
    fontBold,
    "-pointsize",
    "35",
    "-fill",
    "white",
    "-annotate",
    "+151+141",
    "HOGUMETER",
    "-font",
    fontBold,
    "-pointsize",
    "92",
    "-interline-spacing",
    "10",
    "-fill",
    "#2A1813",
    "-annotate",
    "+80+296",
    screen.title,
    "-font",
    fontRegular,
    "-pointsize",
    "39",
    "-fill",
    "#5B4035",
    "-annotate",
    "+84+565",
    screen.eyebrow,
    "-fill",
    "#D65A32",
    "-draw",
    "roundrectangle 80,590 142,600 5,5",
    "-font",
    fontRegular,
    "-pointsize",
    "29",
    "-fill",
    "#6F625D",
    "-annotate",
    "+84+638",
    "실제 택시요금과 무관한 재미용 앱",
    "-fill",
    "rgba(42,24,19,0.08)",
    "-draw",
    "roundrectangle 183,682 1131,2681 82,82",
    frame,
    "-geometry",
    "+171+640",
    "-compose",
    "over",
    "-composite",
    "-background",
    "#FFF9F3",
    "-alpha",
    "remove",
    "-alpha",
    "off",
    output
  );

  run(
    output,
    "-resize",
    "1284x2778!",
    "-alpha",
    "off",
    resolve(actual65Dir, screen.output)
  );
}

console.log(`Generated ${screens.length} requested images in ${outputDir}`);
console.log(`Generated ${screens.length} actual 6.5-inch images in ${actual65Dir}`);
