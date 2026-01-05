//
//  LocationManager.swift
//  Earthlord
//
//  GPS 定位管理器：处理用户定位权限和位置更新
//

import Foundation
import CoreLocation
import Combine  // ⚠️ 重要：@Published 需要这个框架

/// GPS 定位管理器
class LocationManager: NSObject, ObservableObject {
    // MARK: - Properties

    /// 用户当前位置
    @Published var userLocation: CLLocationCoordinate2D?

    /// 定位权限状态
    @Published var authorizationStatus: CLAuthorizationStatus

    /// 错误信息
    @Published var locationError: String?

    // MARK: - Path Tracking Properties

    /// 是否正在追踪路径
    @Published var isTracking: Bool = false

    /// 路径坐标数组（存储 WGS-84 原始坐标）
    @Published var pathCoordinates: [CLLocationCoordinate2D] = []

    /// 路径更新版本号（用于触发 SwiftUI 更新）
    @Published var pathUpdateVersion: Int = 0

    /// 路径是否闭合
    @Published var isPathClosed: Bool = false

    /// CoreLocation 管理器
    private let locationManager = CLLocationManager()

    /// 当前位置（用于 Timer 采点）
    private var currentLocation: CLLocation?

    /// 路径更新定时器（每 2 秒采点一次）
    private var pathUpdateTimer: Timer?

    // MARK: - Computed Properties

    /// 是否已授权定位
    var isAuthorized: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    /// 是否被拒绝定位
    var isDenied: Bool {
        return authorizationStatus == .denied || authorizationStatus == .restricted
    }

    // MARK: - Initialization

    override init() {
        // 初始化授权状态
        self.authorizationStatus = locationManager.authorizationStatus

        super.init()

        // 配置定位管理器
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // 最高精度
        locationManager.distanceFilter = 10  // 移动10米才更新位置
    }

    // MARK: - Public Methods

    /// 请求定位权限
    func requestPermission() {
        print("📍 请求定位权限")
        locationManager.requestWhenInUseAuthorization()
    }

    /// 开始更新位置
    func startUpdatingLocation() {
        guard isAuthorized else {
            print("⚠️ 未授权定位，无法开始更新位置")
            locationError = "请在设置中允许定位权限"
            return
        }

        print("📍 开始更新位置")
        locationManager.startUpdatingLocation()
    }

    /// 停止更新位置
    func stopUpdatingLocation() {
        print("📍 停止更新位置")
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Path Tracking Methods

    /// 开始路径追踪
    func startPathTracking() {
        guard isAuthorized else {
            print("⚠️ 未授权定位，无法开始路径追踪")
            locationError = "请先允许定位权限"
            return
        }

        print("🚩 开始路径追踪")
        isTracking = true
        pathCoordinates.removeAll()
        pathUpdateVersion = 0
        isPathClosed = false

        // 启动定时器（每 2 秒采点一次）
        pathUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.recordPathPoint()
        }
    }

    /// 停止路径追踪
    func stopPathTracking() {
        print("🛑 停止路径追踪")
        isTracking = false

        // 停止定时器
        pathUpdateTimer?.invalidate()
        pathUpdateTimer = nil
    }

    /// 清除路径
    func clearPath() {
        print("🗑️ 清除路径")
        pathCoordinates.removeAll()
        pathUpdateVersion = 0
        isPathClosed = false
    }

    /// 记录路径点（定时器回调）
    private func recordPathPoint() {
        guard isTracking, let location = currentLocation else { return }

        let coordinate = location.coordinate

        // 如果是第一个点，直接记录
        if pathCoordinates.isEmpty {
            pathCoordinates.append(coordinate)
            pathUpdateVersion += 1
            print("📍 记录起点: \(coordinate.latitude), \(coordinate.longitude)")
            return
        }

        // 检查距离上个点是否超过 10 米
        guard let lastCoordinate = pathCoordinates.last else { return }
        let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
        let distance = location.distance(from: lastLocation)

        // 只有移动超过 10 米才记录新点
        if distance > 10 {
            pathCoordinates.append(coordinate)
            pathUpdateVersion += 1
            print("📍 记录新点（距上个点 \(Int(distance))米）: \(coordinate.latitude), \(coordinate.longitude)")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    /// 授权状态变化时调用
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 授权状态变化: \(manager.authorizationStatus.rawValue)")

        // 更新授权状态
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }

        // 如果已授权，开始更新位置
        if isAuthorized {
            startUpdatingLocation()
        } else if isDenied {
            DispatchQueue.main.async {
                self.locationError = "定位权限被拒绝，请在设置中允许"
            }
        }
    }

    /// 位置更新时调用
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        print("📍 位置更新: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // ⚠️ 关键：保存当前位置供 Timer 使用
        self.currentLocation = location

        // 更新用户位置
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.locationError = nil
        }
    }

    /// 定位失败时调用
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ 定位失败: \(error.localizedDescription)")

        DispatchQueue.main.async {
            self.locationError = "定位失败: \(error.localizedDescription)"
        }
    }
}
