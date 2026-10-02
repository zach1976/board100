# 训练素材（drill JSON）不发版更新 — 执行计划

日期：2026-09-29。计划人：Fable 5.1；执行：Opus。

## 0. 现状（已核实，不要再查一遍）

OTA 通道**已经存在并且线上在跑**，2026-09-06 上线（commit `9e1c3278`）：

- 客户端 `tactics_board/lib/services/drill_library_service.dart`：
  先答 bundle 或本地缓存，后台 `GET https://tacticsboard.100for1.com/api/v1/drills/{sport}`；
  服务端 `version` **严格大于**手头版本才落盘（`Documents/drills/<sport>.json`）；
  bundle 比缓存新或相等时 bundle 赢；`FLUTTER_TEST` 下不联网。
- 服务端 `backend/app/Http/Controllers/DrillPackController.php`，路由 `GET /api/v1/drills/{sport}`，
  读 `storage/app/drills/{sport}.json`（`FILESYSTEM_DISK=local`），控制器内 gzip，`Cache-Control: max-age=3600`。
- 线上现在返回的是 9 月 6 日那版内容，`"version": 1`。

**它为什么从来没起过作用**：`tools/drills/engine.py` 第 1675 行把 version 写死成 `1`。
bundle 是 1，服务器是 1，客户端永远判「不比我新」。机制齐全，就差版本号会动。

**其他事实**：
- 包怎么上服务器：`~/projects/.env` 里有 `SSH_HOST/SSH_USER/SSH_KEY_FILE`（EC2，密钥在
  `~/projects/server_keys/`），能直接 scp。**本计划第一稿写成「为空」，是计划人用 `grep -o` 把值截掉了
  ——执行时已更正。** 服务器是 Apache + PHP 8.2.31。
- Laravel 11 的 `local` 盘根在 `storage/app/private/`，所以包的真实路径是
  `storage/app/private/drills/<sport>.json`，不是 `storage/app/drills/`。写错路径不会报错、也不会生效。
- 2.0.0（线上）和 2.0.1（已上传 build 4）的解析器对新字段兼容：`PlayerIcon.fromJson` 只读具名键，
  `moveCarriers` 被忽略后回退到几何判断；`holds`/`faceLock` 两版都读；`Drill.fromJson` 的
  `usage/frame/offSurface/tight` 都有默认值。所以**给老客户端推新包是安全的**。
- 2.0.1 现在停在 ASC `PREPARE_FOR_SUBMISSION`（build 4 已附加）。**本计划任何步骤都不得碰 ASC，不得送审。**

## 1. 目标

1. 以后改完 drill 数据，跑一个命令就能让所有已安装的 app（含线上的 2.0.0）在下次打开时拿到新包，不用发版。
2. 版本号确定性：`gen_drills.py --check` 仍然可用（同样的输入 → 同样的输出）。
3. 不新增任何付费服务；不改变现有 API 形状（老客户端在用）。

## 2. 阶段 A — 只动生成器和服务器上的文件（不需要发版，今天就能生效）

### A1 版本号来源
- 新建 `tools/drills/pack_version.txt`，内容一个整数，初值 `2`（线上和 bundle 都是 1）。
- `engine.py` 的 `build()` 返回的 `"version"` 改成读这个文件（在 `gen_drills.py` 读一次传进去，或 engine 里读；二选一，别两处读）。
- 只有**发布**才把它 +1；平时改内容不动它（bundle 里的 version 和上次发布一致，打包进 app 后「平手 bundle 赢」仍然成立）。

### A2 发布工具 `tools/publish_drills.py`
步骤，每步可单独跑、可重复跑：
1. `bump`：`pack_version.txt` +1，`gen_drills.py` 重新生成 15 个包 + `index.json`。
2. `verify`：本地把 15 个包按客户端同样的形状解析一遍（`sport/version/drills[]`、每个 drill 有 `id/name/board`、
   每个 board 有 `players`），并打印每个运动的数量；任何一个不通过就停。
3. `upload`：把 15 个 `tactics_board/assets/drills/<sport>.json` scp 到服务器 `storage/app/private/drills/`
   （`tools/publish_drills.py` 已实现；旧版先备份到同目录旁的 `drills_backup_v1_20260929/`）。
4. `check`：逐个 `GET https://tacticsboard.100for1.com/api/v1/drills/<sport>`（带 `Accept-Encoding: gzip`），
   核对 `version` 等于新号、drill 数量等于本地；注意 `max-age=3600`，加 `?v=<版本>` 或 `Cache-Control: no-cache` 绕过缓存核对。
5. 提交：`pack_version.txt` 和重生成的 JSON 一起进 git，提交说明写「发布了第 N 版包」。

不要给 `publish_drills.py` 加「顺便送审」之类的功能。

### A3 验收
- `curl -s .../drills/soccer | head -c 200` 显示 `"version": 2`，drills 137。
- 模拟器里的 2.0.1 打开 Drills 页两次（第一次后台拉，第二次读缓存），`Documents/drills/soccer.json` 出现且 version 为 2。
  （`xcrun simctl get_app_container <udid> com.zach.soccerBoard data` 找到目录。）
- 真机上的 2.0.1 同样验证一次（手机已装好，UDID `00008150-00026C30213A401C`）。

## 3. 阶段 B — 客户端加固（**三条都做完了，2026-09-30**；要进下一个 build）

1. ✅ **数量不再来自 bundle 的 `index.json`**：`bundledCounts()` 改成「有缓存包就数缓存包」，
   否则读 index。（`drill_library_service.dart`）
2. ✅ **`minClient`**：包里的 `minClient` 由 `tools/drills/min_client.txt` 写入（现为 `2.0.0`），
   客户端版本低于它就不落盘。老客户端不认识这个键，照旧。
3. ✅ **ETag / If-None-Match**：控制器按文件 md5 出 `ETag` 并认 `If-None-Match`，304 直接返回；
   同时补了 `Vary: Accept-Encoding`（一个 URL 同时供 gzip 和明文）。客户端把 tag 写在
   `Documents/drills/<sport>.etag`，**只在包还在时**才带上去——tag 没了包还在、或包没了 tag 还在，
   都会让下一次启动要么白下要么永远不下。
4. 服务端只加了响应头，API 形状没动。

**没做的**：`DrillPackController.php` 的改动**还没部署**（部署方式见 §4），
所以线上暂时仍是无 ETag 的老控制器——客户端带 `If-None-Match` 对老控制器无害，照旧 200 下载。

## 4. 把文件放到服务器上（已解决，留作记录）

执行者按这个顺序找，找不到就**停下来问用户**，不要猜、不要试密码、不要开新服务：
1. `~/projects/.env`、`~/projects/*/.env*`、`backend/.env`（本机有没有）里的 SSH/SFTP/FTP 变量。
2. `~/.ssh/config` 里有没有 100for1 / tacticsboard 的 Host。
3. 记忆目录 `~/.claude/projects/-Users-zhenyusong-projects-board100/memory/` 和 `projects/zachs_app_base.md` 里关于后端部署的段落。
4. 以上都没有 → 向用户要一条能把文件放到 `storage/app/drills/` 的路径（SSH 主机+用户、或 SFTP、或后台面板），并把它写进 `~/projects/.env`（不要进 git）。

备选（不推荐首选，因为它本身也要部署后端）：给后端加 `PUT /api/v1/drills/{sport}`，用一个环境变量里的 admin token 鉴权。只有在用户明确说服务器只能靠后端部署更新时才走这条。

## 5. 约束

- `board100/CLAUDE.md` 的编辑规则：最小 diff，不重构无关代码。
- 不做任何会产生费用的操作（不开 S3/CDN/新主机）。
- 不碰 App Store Connect；不上传 build；不送审。2.0.1 的版本记录保持原样。
- 提交信息末尾用会话当前的署名行。
- 完成后写一份简短报告：改了哪些文件、`pack_version` 现在是几、线上 15 个包各自的 version 和数量、模拟器/真机验证结果、阶段 B 做了没有、以及卡在哪。
