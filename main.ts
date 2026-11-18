// Brainrot Bay's entry program (Node 22, standard library only). It hands the
// game in: the Rojo-built place, the Luau sources, the screenshots and the play
// link go to /output, and the dossier the judge reads is written from them with
// make.fun's vendored library. Run it as the grader does, with out/ standing in
// for /output:
//
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
//
// The grader refuses any name under /output that does not start with a letter, a
// digit or _ (a stray .gitkeep or .DS_Store fails the whole entry), so the two
// directory copies below skip every dotted name, at any depth.

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const repoRoot = fileURLToPath(new URL('.', import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// cpSync filter: keep every entry whose name does not start with a dot.
function isNotDotted(entryPath: string): boolean {
  return !basename(entryPath).startsWith('.');
}

mkdirSync(outputDir, { recursive: true });
copyFileSync(join(repoRoot, 'game.rbxl'), join(outputDir, 'game.rbxl'));
copyFileSync(join(repoRoot, 'PLAY.json'), join(outputDir, 'PLAY.json'));
cpSync(join(repoRoot, 'src'), join(outputDir, 'src'), { recursive: true, filter: isNotDotted });
mkdirSync(join(outputDir, 'screenshots'), { recursive: true });
if (existsSync(join(repoRoot, 'screenshots'))) {
  cpSync(join(repoRoot, 'screenshots'), join(outputDir, 'screenshots'), { recursive: true, filter: isNotDotted });
}

// The gate's own caps, from the bounty's gate.json: only text_max_bytes shapes
// the dossier's bytes; the rest make this program fail exactly where the sealed
// scorer would refuse the entry (too many or too large screenshots, a place past
// its instance, script-source or script-path caps).
writeFileSync(
  join(outputDir, 'dossier.json'),
  buildDossier(outputDir, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);
