# CI/CD

参考 [AHU-AIO](https://github.com/MoeclubM/AHU-AIO) 的 GitHub Actions 流程。

## 工作流

| 文件 | 触发 | 说明 |
|------|------|------|
| `beta.yml` | `main`/`master` 推送、手动 | 格式化、分析、测试；Beta 多平台构建 |
| `main.yml` | `v*` 标签、手动 | 正式版多平台构建并创建 GitHub Release |

CI 会在构建前执行 `flutter create` 生成 Android / Windows / macOS / Linux 原生工程，并对 Android 运行 `scripts/ci_configure_android.py` 注入签名与 USB 权限配置。

## Secrets（仓库 Settings → Secrets and variables → Actions）

| Secret | 说明 |
|--------|------|
| `KEYSTORE_PASSWORD` | JKS 库密码与 key 密码（当前约定：`0d000721`） |
| `KEYSTORE_BASE64` | `release-key.jks` 的 Base64 内容 |

本地生成并上传示例（PowerShell，仓库根目录）：

```powershell
.\scripts\create_android_keystore.ps1
$bytes = [IO.File]::ReadAllBytes("android\app\release-key.jks")
[Convert]::ToBase64String($bytes) | Set-Content -NoNewline keystore.b64.txt
gh secret set KEYSTORE_PASSWORD --repo MoeclubM/MultiSignal --body "0d000721"
gh secret set KEYSTORE_BASE64 --repo MoeclubM/MultiSignal < keystore.b64.txt
Remove-Item keystore.b64.txt
```

Key alias：`multisignal`（与工作流环境变量 `KEY_ALIAS` 一致）。

## 发布

```bash
git tag v0.1.0
git push origin v0.1.0
```