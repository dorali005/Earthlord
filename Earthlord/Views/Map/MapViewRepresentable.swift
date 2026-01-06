//
//  MapViewRepresentable.swift
//  Earthlord
//
//  MKMapView 的 SwiftUI 包装器：显示地图并自动居中到用户位置
//

import SwiftUI
import MapKit

/// 地图视图包装器
struct MapViewRepresentable: UIViewRepresentable {
    // MARK: - Properties

    /// 用户位置（双向绑定）
    @Binding var userLocation: CLLocationCoordinate2D?

    /// 是否已定位到用户（防止重复居中）
    @Binding var hasLocatedUser: Bool

    /// 路径追踪坐标数组
    @Binding var trackingPath: [CLLocationCoordinate2D]

    /// 路径更新版本号（触发轨迹重绘）
    var pathUpdateVersion: Int

    /// 是否正在追踪
    var isTracking: Bool

    // MARK: - UIViewRepresentable Methods

    /// 创建地图视图
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()

        // 基础配置
        mapView.mapType = .hybrid  // 卫星图 + 道路标签（末世废土风格）
        mapView.pointOfInterestFilter = .excludingAll  // 隐藏所有 POI 标签（星巴克、麦当劳等）
        mapView.showsBuildings = false  // 隐藏 3D 建筑
        mapView.showsUserLocation = true  // ⚠️ 关键：显示用户位置蓝点，这会触发位置更新
        mapView.isZoomEnabled = true  // 允许缩放
        mapView.isScrollEnabled = true  // 允许拖动
        mapView.isRotateEnabled = true  // 允许旋转
        mapView.isPitchEnabled = false  // 禁用倾斜（保持平面视角）

        // ⚠️ 关键：设置代理，否则 didUpdate userLocation 不会被调用
        mapView.delegate = context.coordinator

        // 应用末世滤镜效果
        applyApocalypseFilter(to: mapView)

        print("🗺️ 地图视图已创建")

        return mapView
    }

    /// 更新地图视图
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 更新路径追踪轨迹
        context.coordinator.updateTrackingPath(mapView: uiView, path: trackingPath, version: pathUpdateVersion)
    }

    /// 创建协调器
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Private Methods

    /// 应用末世滤镜效果（降低饱和度、添加棕褐色调）
    private func applyApocalypseFilter(to mapView: MKMapView) {
        // 色调控制：降低饱和度和亮度
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls?.setValue(-0.15, forKey: kCIInputBrightnessKey)  // 稍微变暗
        colorControls?.setValue(0.5, forKey: kCIInputSaturationKey)  // 降低饱和度

        // 棕褐色调：废土的泛黄效果
        let sepiaFilter = CIFilter(name: "CISepiaTone")
        sepiaFilter?.setValue(0.65, forKey: kCIInputIntensityKey)  // 中等强度

        // 应用滤镜到地图图层
        if let colorControls = colorControls, let sepiaFilter = sepiaFilter {
            mapView.layer.filters = [colorControls, sepiaFilter]
        }

        print("🎨 末世滤镜已应用")
    }

    // MARK: - Coordinator

    /// 协调器：处理地图事件
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        /// 首次居中标志（防止重复居中）
        private var hasInitialCentered = false

        /// 上次更新的路径版本号（防止重复绘制）
        private var lastPathVersion: Int = -1

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        // MARK: - MKMapViewDelegate Methods

        /// ⭐ 关键方法：用户位置更新时调用（这是地图自动居中的核心）
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            // 获取位置
            guard let location = userLocation.location else { return }

            print("📍 地图收到位置更新: \(location.coordinate.latitude), \(location.coordinate.longitude)")

            // 更新绑定的位置
            DispatchQueue.main.async {
                self.parent.userLocation = location.coordinate
            }

            // 首次获得位置时，自动居中地图
            guard !hasInitialCentered else {
                print("📍 已完成首次居中，跳过")
                return
            }

            // 创建居中区域（约 1 公里范围）
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )

            print("🎯 首次居中地图到用户位置")

            // 平滑居中地图
            mapView.setRegion(region, animated: true)

            // 标记已完成首次居中
            hasInitialCentered = true

            // 更新外部状态
            DispatchQueue.main.async {
                self.parent.hasLocatedUser = true
            }
        }

        /// 地图区域变化完成时调用
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // 可以在这里记录地图中心点
            let center = mapView.region.center
            print("🗺️ 地图中心: \(center.latitude), \(center.longitude)")
        }

        /// 地图加载完成时调用
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            print("🗺️ 地图加载完成")
        }

        /// 自定义用户位置标注（可选）
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // 如果是用户位置，使用默认样式
            if annotation is MKUserLocation {
                return nil
            }

            // 其他标注可以在这里自定义
            return nil
        }

        /// ⭐ 关键方法：渲染地图覆盖物（轨迹线）
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // 如果是路径追踪的轨迹线
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 0, green: 1, blue: 1, alpha: 0.9)  // 明亮的青色轨迹线
                renderer.lineWidth = 8  // 更粗的线宽
                renderer.lineCap = .round  // 圆头
                renderer.lineJoin = .round  // 圆角连接
                return renderer
            }

            // 默认渲染器
            return MKOverlayRenderer(overlay: overlay)
        }

        // MARK: - Path Tracking Methods

        /// 更新路径追踪轨迹
        func updateTrackingPath(mapView: MKMapView, path: [CLLocationCoordinate2D], version: Int) {
            // 版本号未变化，跳过更新
            guard version != lastPathVersion else { return }

            // 更新版本号
            lastPathVersion = version

            // 移除所有旧的轨迹线
            mapView.removeOverlays(mapView.overlays)

            // 如果路径为空或只有一个点，不绘制轨迹
            guard path.count >= 2 else {
                print("📍 路径点不足（\(path.count)个），不绘制轨迹")
                return
            }

            // ⚠️ 关键：转换为 GCJ-02 坐标（解决中国 GPS 偏移问题）
            var gcjPath = CoordinateConverter.wgs84ToGcj02(path)

            // 创建轨迹线（需要使用 var 和 & 来传递可变指针）
            let polyline = MKPolyline(coordinates: &gcjPath, count: gcjPath.count)

            // 添加轨迹线到地图
            mapView.addOverlay(polyline)

            print("📍 已绘制轨迹线（\(gcjPath.count)个点）")
        }
    }
}
