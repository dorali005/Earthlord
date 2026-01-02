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

    /// CoreLocation 管理器
    private let locationManager = CLLocationManager()

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
