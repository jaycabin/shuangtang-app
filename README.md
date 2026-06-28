# 双糖 (ShuangTang / DoubleSugar)

> 两颗心，双倍糖。Two hearts, double the sweetness.

情侣专属私密空间APP，用"糖"的隐喻串联所有甜蜜互动。

## 技术栈

- **前端**: Flutter 3.x (Riverpod, flutter_localizations)
- **后端**: Go 1.22+ (Gin, PostgreSQL, Redis, MinIO)
- **部署**: Docker Compose, GitHub Actions CI/CD

[![CI](https://github.com/jaycabin/shuangtang-app/actions/workflows/ci.yml/badge.svg)](https://github.com/jaycabin/shuangtang-app/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.19-blue)](https://flutter.dev)

## 快速启动

```bash
# 后端
cd backend
cp .env.example .env
make up    # 启动所有服务
make dev   # 热重载开发

# 前端
cd frontend
flutter pub get
flutter run
```

## 功能模块

| 模块 | 说明 |
|------|------|
| 时光轴 | 混合时间线展示情侣动态 |
| 纪念日 | 重要日期倒计时与提醒 |
| 每日打卡 | 情侣任务打卡挑战 |
| 位置共享 | 实时位置追踪与靠近提醒 |
| 情侣相册 | 照片同步与拼图 |
| 愿望清单 | 心愿认领与完成 |
| 悄悄话 | 加密消息传递 |
| 双糖闹钟 | 仅对方可关闭的闹钟 |

## 多语言支持

默认简体中文，支持英文，可在 App 内实时切换。

## 管理后台

访问 `/admin` 路径，使用 `.env` 中配置的管理员账号登录。
