# 双糖 Supabase 设置指南

## 1. 创建 Supabase 项目

1. 打开 [app.supabase.com](https://app.supabase.com) → 点击 **New project**
2. 填写：
   - **Name**: `shuangtang-app`（或任意名称）
   - **Database Password**: 点击生成并保存
   - **Region**: 选择最近的（如 Tokyo 或 Singapore）
3. 等待项目创建完成（约 2 分钟）

## 2. 配置数据库

在 Supabase Dashboard 左侧点击 **SQL Editor**，新建一个查询，粘贴以下文件内容并运行：

```
📄 supabase/migrations/00001_schema.sql
```

这个文件包含了所有表的创建和行级安全策略（RLS）。

## 3. 获取连接信息

左侧点击 **Project Settings → API**：

```
Project URL:      https://XXXXXXXXXXXX.supabase.co
anon public key:  eyJhbGciOiJIUzI1NiIs...
```

## 4. 配置 Flutter

在 `frontend/lib/constants/constants.dart` 中填入上述值：

```dart
static const String supabaseUrl = 'https://XXXXXXXXXXXX.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIs...';
```

在 `frontend/lib/main.dart` 中同样替换：

```dart
await Supabase.initialize(
  url: 'https://XXXXXXXXXXXX.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIs...',
);
```

## 5. 配置 Auth（邮箱+密码登录）

1. 左侧 **Authentication → Providers**
2. 确保 **Email** 已启用
3. 建议关闭 "Confirm email"（MVP 阶段可以跳过邮箱验证）
4. 如果需要自定义发件域名，在 **Settings → Auth → SMTP Settings** 配置

## 6. 创建 Storage Bucket

1. 左侧 **Storage** → **New bucket**
2. 名称: `albums`
3. 公开 ✅
4. 在 **Storage → Policies** 中设置 RLS：

```sql
-- 允许情侣成员读取
create policy "Couple members can read albums"
on storage.objects for select
using (bucket_id = 'albums');

-- 允许认证用户上传
create policy "Auth users can upload to albums"
on storage.objects for insert
with check (bucket_id = 'albums' and auth.role() = 'authenticated');
```

## 7. 测试连接

```bash
cd frontend
flutter pub get
flutter gen-l10n
flutter run
```

注册 → 创建/加入情侣空间 → 发瞬间 → 实时同步

---

## 架构对比一览

| 模块 | 旧（Go 后端） | 新（Supabase） |
|------|--------------|---------------|
| 用户认证 | JWT + Redis 验证码 | Supabase Auth（邮箱+密码） |
| 数据库 | PostgreSQL 自建 | Supabase PostgreSQL |
| 实时通信 | WebSocket 自建 | Supabase Realtime |
| 文件存储 | MinIO / 本地 | Supabase Storage |
| 权限控制 | Go middleware | PostgreSQL RLS |
| 管理后台 | Go HTML 模板 | Supabase Dashboard |
| 部署 | Docker Compose | 无需部署 |
