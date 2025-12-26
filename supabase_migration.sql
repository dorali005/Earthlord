-- ========================================
-- 地球新主 (Earthlord) 数据库迁移
-- 创建日期: 2025-12-24
-- 说明: 创建核心游戏数据表
-- ========================================

-- ========================================
-- 1. 创建 profiles 表 (用户资料)
-- ========================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 为 profiles 表添加注释
COMMENT ON TABLE public.profiles IS '用户资料表';
COMMENT ON COLUMN public.profiles.id IS '用户ID，关联 auth.users';
COMMENT ON COLUMN public.profiles.username IS '用户名，全局唯一';
COMMENT ON COLUMN public.profiles.avatar_url IS '用户头像URL';
COMMENT ON COLUMN public.profiles.created_at IS '账号创建时间';
COMMENT ON COLUMN public.profiles.updated_at IS '最后更新时间';

-- 创建索引
CREATE INDEX IF NOT EXISTS profiles_username_idx ON public.profiles(username);

-- ========================================
-- 2. 创建 territories 表 (领地)
-- ========================================
CREATE TABLE IF NOT EXISTS public.territories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    path JSONB NOT NULL,
    area NUMERIC(12, 2) NOT NULL CHECK (area > 0),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    last_active_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    allow_trade BOOLEAN DEFAULT true NOT NULL
);

-- 为 territories 表添加注释
COMMENT ON TABLE public.territories IS '领地表';
COMMENT ON COLUMN public.territories.id IS '领地唯一ID';
COMMENT ON COLUMN public.territories.user_id IS '领地所有者ID';
COMMENT ON COLUMN public.territories.name IS '领地名称';
COMMENT ON COLUMN public.territories.path IS 'GPS路径点数组 [{lat, lng}, ...]';
COMMENT ON COLUMN public.territories.area IS '领地面积（平方米）';
COMMENT ON COLUMN public.territories.created_at IS '领地创建时间';
COMMENT ON COLUMN public.territories.updated_at IS '最后更新时间';
COMMENT ON COLUMN public.territories.last_active_at IS '最后活跃时间';
COMMENT ON COLUMN public.territories.allow_trade IS '是否允许交易';

-- 创建索引
CREATE INDEX IF NOT EXISTS territories_user_id_idx ON public.territories(user_id);
CREATE INDEX IF NOT EXISTS territories_created_at_idx ON public.territories(created_at DESC);
CREATE INDEX IF NOT EXISTS territories_area_idx ON public.territories(area DESC);

-- ========================================
-- 3. 创建 pois 表 (兴趣点)
-- ========================================
CREATE TABLE IF NOT EXISTS public.pois (
    id TEXT PRIMARY KEY,
    poi_type TEXT NOT NULL,
    name TEXT NOT NULL,
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    discovered_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    discovered_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    last_searched_at TIMESTAMPTZ,
    search_count INTEGER DEFAULT 0 NOT NULL
);

-- 为 pois 表添加注释
COMMENT ON TABLE public.pois IS 'POI兴趣点表';
COMMENT ON COLUMN public.pois.id IS 'POI外部唯一ID（来自地图服务）';
COMMENT ON COLUMN public.pois.poi_type IS 'POI类型（hospital/supermarket/factory/park等）';
COMMENT ON COLUMN public.pois.name IS 'POI名称';
COMMENT ON COLUMN public.pois.latitude IS '纬度';
COMMENT ON COLUMN public.pois.longitude IS '经度';
COMMENT ON COLUMN public.pois.discovered_by IS '首次发现者ID';
COMMENT ON COLUMN public.pois.discovered_at IS '首次发现时间';
COMMENT ON COLUMN public.pois.last_searched_at IS '最后搜刮时间';
COMMENT ON COLUMN public.pois.search_count IS '累计搜刮次数';

-- 创建索引
CREATE INDEX IF NOT EXISTS pois_poi_type_idx ON public.pois(poi_type);
CREATE INDEX IF NOT EXISTS pois_discovered_by_idx ON public.pois(discovered_by);
CREATE INDEX IF NOT EXISTS pois_location_idx ON public.pois(latitude, longitude);

-- ========================================
-- 4. 启用行级安全 (RLS)
-- ========================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.territories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pois ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 5. 创建 RLS 策略
-- ========================================

-- profiles 表策略
-- 允许用户查看所有用户资料
CREATE POLICY "公开查看用户资料"
    ON public.profiles FOR SELECT
    USING (true);

-- 允许用户插入自己的资料
CREATE POLICY "用户可以插入自己的资料"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 允许用户更新自己的资料
CREATE POLICY "用户可以更新自己的资料"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- territories 表策略
-- 允许查看所有领地
CREATE POLICY "公开查看所有领地"
    ON public.territories FOR SELECT
    USING (true);

-- 允许用户创建自己的领地
CREATE POLICY "用户可以创建自己的领地"
    ON public.territories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 允许用户更新自己的领地
CREATE POLICY "用户可以更新自己的领地"
    ON public.territories FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 允许用户删除自己的领地
CREATE POLICY "用户可以删除自己的领地"
    ON public.territories FOR DELETE
    USING (auth.uid() = user_id);

-- pois 表策略
-- 允许查看所有POI
CREATE POLICY "公开查看所有POI"
    ON public.pois FOR SELECT
    USING (true);

-- 允许已登录用户发现新POI
CREATE POLICY "已登录用户可以发现新POI"
    ON public.pois FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- 允许已登录用户更新POI（搜刮记录）
CREATE POLICY "已登录用户可以更新POI"
    ON public.pois FOR UPDATE
    USING (auth.uid() IS NOT NULL);

-- ========================================
-- 6. 创建触发器函数（自动更新 updated_at）
-- ========================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为 profiles 表添加触发器
CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 为 territories 表添加触发器
CREATE TRIGGER territories_updated_at
    BEFORE UPDATE ON public.territories
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ========================================
-- 7. 创建自动创建 profile 的触发器
-- ========================================
-- 当新用户注册时，自动创建 profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建触发器
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ========================================
-- 8. 创建辅助视图
-- ========================================

-- 用户统计视图
CREATE OR REPLACE VIEW public.user_stats AS
SELECT
    p.id,
    p.username,
    p.avatar_url,
    p.created_at,
    COUNT(DISTINCT t.id) AS territory_count,
    COALESCE(SUM(t.area), 0) AS total_area,
    COUNT(DISTINCT poi.id) AS discovered_pois
FROM public.profiles p
LEFT JOIN public.territories t ON t.user_id = p.id
LEFT JOIN public.pois poi ON poi.discovered_by = p.id
GROUP BY p.id, p.username, p.avatar_url, p.created_at;

-- 为视图添加注释
COMMENT ON VIEW public.user_stats IS '用户统计视图：包含领地数量、总面积、发现的POI数量';

-- ========================================
-- 9. 授予权限
-- ========================================

-- 授予 authenticated 用户对表的访问权限
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.territories TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.pois TO authenticated;

-- 授予 authenticated 用户对视图的查看权限
GRANT SELECT ON public.user_stats TO authenticated;

-- 授予 anon 用户查看权限（游客可以查看但不能修改）
GRANT SELECT ON public.profiles TO anon;
GRANT SELECT ON public.territories TO anon;
GRANT SELECT ON public.pois TO anon;
GRANT SELECT ON public.user_stats TO anon;

-- ========================================
-- 迁移完成
-- ========================================

-- 输出确认信息
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE '地球新主数据库迁移完成！';
    RAISE NOTICE '========================================';
    RAISE NOTICE '已创建的表:';
    RAISE NOTICE '  - profiles (用户资料)';
    RAISE NOTICE '  - territories (领地)';
    RAISE NOTICE '  - pois (兴趣点)';
    RAISE NOTICE '';
    RAISE NOTICE '已创建的视图:';
    RAISE NOTICE '  - user_stats (用户统计)';
    RAISE NOTICE '';
    RAISE NOTICE '已启用 RLS 并配置安全策略';
    RAISE NOTICE '已创建必要的索引和触发器';
    RAISE NOTICE '========================================';
END $$;
