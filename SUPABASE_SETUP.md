# Supabase 数据库设置指南

## 📋 概述

此文件包含《地球新主 (Earthlord)》游戏的完整数据库迁移脚本。

---

## 🚀 如何应用迁移

### 方法 1: 使用 Supabase Dashboard（推荐）

1. **登录 Supabase Dashboard**
   - 访问：https://supabase.com/dashboard
   - 选择你的项目：`vbwenhbxnkplsgneairf`

2. **打开 SQL Editor**
   - 在左侧菜单中点击 `SQL Editor`
   - 点击 `New Query` 创建新查询

3. **复制并执行 SQL**
   - 打开 `supabase_migration.sql` 文件
   - 复制全部内容
   - 粘贴到 SQL Editor 中
   - 点击 `Run` 按钮执行

4. **验证结果**
   - 在左侧菜单中点击 `Table Editor`
   - 确认已创建以下表：
     - ✅ profiles
     - ✅ territories
     - ✅ pois

---

## 📊 数据库结构

### 1️⃣ profiles（用户资料）

| 字段 | 类型 | 说明 |
|-----|------|------|
| id | UUID | 主键，关联 auth.users |
| username | TEXT | 用户名（唯一） |
| avatar_url | TEXT | 头像URL |
| created_at | TIMESTAMPTZ | 创建时间 |
| updated_at | TIMESTAMPTZ | 更新时间 |

**特性**:
- ✅ 启用 RLS
- ✅ 自动创建：新用户注册时自动创建 profile
- ✅ 自动更新：updated_at 字段自动更新

**RLS 策略**:
- 所有人可以查看用户资料
- 用户只能修改自己的资料

---

### 2️⃣ territories（领地）

| 字段 | 类型 | 说明 |
|-----|------|------|
| id | UUID | 主键 |
| user_id | UUID | 用户ID（外键） |
| name | TEXT | 领地名称 |
| path | JSONB | GPS路径点数组 |
| area | NUMERIC | 面积（平方米） |
| created_at | TIMESTAMPTZ | 创建时间 |
| updated_at | TIMESTAMPTZ | 更新时间 |
| last_active_at | TIMESTAMPTZ | 最后活跃时间 |
| allow_trade | BOOLEAN | 是否允许交易 |

**特性**:
- ✅ 启用 RLS
- ✅ 自动更新 updated_at
- ✅ 面积必须大于 0

**RLS 策略**:
- 所有人可以查看领地
- 用户只能修改/删除自己的领地

**示例 path 数据格式**:
```json
[
  {"lat": 22.5431, "lng": 114.0579},
  {"lat": 22.5432, "lng": 114.0580},
  {"lat": 22.5433, "lng": 114.0581}
]
```

---

### 3️⃣ pois（兴趣点）

| 字段 | 类型 | 说明 |
|-----|------|------|
| id | TEXT | 主键（外部ID） |
| poi_type | TEXT | POI类型 |
| name | TEXT | POI名称 |
| latitude | NUMERIC | 纬度 |
| longitude | NUMERIC | 经度 |
| discovered_by | UUID | 发现者ID |
| discovered_at | TIMESTAMPTZ | 发现时间 |
| last_searched_at | TIMESTAMPTZ | 最后搜刮时间 |
| search_count | INTEGER | 搜刮次数 |

**特性**:
- ✅ 启用 RLS
- ✅ 记录发现者和搜刮统计

**POI类型**:
- `hospital` - 医院
- `supermarket` - 超市
- `factory` - 工厂
- `park` - 公园
- `bank` - 银行
- 等等...

**RLS 策略**:
- 所有人可以查看 POI
- 已登录用户可以发现和更新 POI

---

## 📈 辅助视图

### user_stats（用户统计）

自动聚合用户数据的视图：

| 字段 | 说明 |
|-----|------|
| id | 用户ID |
| username | 用户名 |
| avatar_url | 头像 |
| created_at | 注册时间 |
| territory_count | 领地数量 |
| total_area | 总领地面积 |
| discovered_pois | 发现的POI数量 |

**使用示例**:
```sql
-- 查询排行榜
SELECT * FROM user_stats
ORDER BY total_area DESC
LIMIT 10;
```

---

## 🔐 安全特性

### ✅ 已启用功能

1. **Row Level Security (RLS)**
   - 所有表都启用了 RLS
   - 配置了细粒度的访问控制策略

2. **自动触发器**
   - 自动创建用户 profile
   - 自动更新 updated_at 时间戳

3. **数据验证**
   - 领地面积必须大于 0
   - 用户名必须唯一
   - 外键约束确保数据完整性

4. **索引优化**
   - 为常用查询字段创建索引
   - 提高查询性能

---

## 🧪 测试 SQL

### 1. 插入测试用户资料

```sql
-- 注意：这需要有对应的 auth.users 记录
-- 通常由认证系统自动创建
INSERT INTO profiles (id, username, avatar_url)
VALUES (
    'your-user-uuid',
    'test_player',
    'https://example.com/avatar.png'
);
```

### 2. 插入测试领地

```sql
INSERT INTO territories (user_id, name, path, area)
VALUES (
    'your-user-uuid',
    '我的第一块领地',
    '[{"lat": 22.5431, "lng": 114.0579}, {"lat": 22.5432, "lng": 114.0580}]',
    1500.50
);
```

### 3. 插入测试POI

```sql
INSERT INTO pois (id, poi_type, name, latitude, longitude, discovered_by)
VALUES (
    'poi_hospital_001',
    'hospital',
    '中心医院',
    22.5431,
    114.0579,
    'your-user-uuid'
);
```

### 4. 查询用户统计

```sql
SELECT * FROM user_stats
WHERE username = 'test_player';
```

---

## 🔧 常用查询

### 查询某个用户的所有领地

```sql
SELECT * FROM territories
WHERE user_id = 'your-user-uuid'
ORDER BY created_at DESC;
```

### 查询面积最大的领地

```sql
SELECT
    t.*,
    p.username
FROM territories t
JOIN profiles p ON t.user_id = p.id
ORDER BY t.area DESC
LIMIT 10;
```

### 查询某个区域内的POI

```sql
SELECT * FROM pois
WHERE latitude BETWEEN 22.5 AND 22.6
  AND longitude BETWEEN 114.0 AND 114.1;
```

### 查询某个用户发现的所有POI

```sql
SELECT * FROM pois
WHERE discovered_by = 'your-user-uuid'
ORDER BY discovered_at DESC;
```

---

## 🛠️ 故障排查

### 问题 1: 权限错误

**错误**: `new row violates row-level security policy`

**解决方案**:
- 确保已登录（有 auth.uid()）
- 检查 RLS 策略是否正确配置
- 在 Supabase Dashboard 中临时禁用 RLS 进行测试

### 问题 2: 外键约束错误

**错误**: `violates foreign key constraint`

**解决方案**:
- 确保引用的 profile/user 存在
- 先创建 profile 再创建 territory

### 问题 3: 唯一约束错误

**错误**: `duplicate key value violates unique constraint`

**解决方案**:
- 用户名已存在，需要使用不同的用户名
- POI ID 已存在，检查是否重复插入

---

## 📚 下一步

1. ✅ **执行迁移脚本**
2. ✅ **在 Swift 中测试连接**（使用 SupabaseTestView）
3. ⬜ **实现用户注册功能**
4. ⬜ **实现领地创建功能**
5. ⬜ **实现 POI 发现功能**

---

## 🔗 相关资源

- [Supabase 文档](https://supabase.com/docs)
- [PostgreSQL 文档](https://www.postgresql.org/docs/)
- [PostGIS 文档](https://postgis.net/docs/)（用于地理空间查询）

---

**创建日期**: 2025-12-24
**版本**: v1.0
**作者**: Youqing Li
