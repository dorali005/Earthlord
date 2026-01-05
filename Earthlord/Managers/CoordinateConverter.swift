//
//  CoordinateConverter.swift
//  Earthlord
//
//  坐标转换工具：WGS-84（GPS原始坐标） → GCJ-02（中国加密坐标）
//

import Foundation
import CoreLocation

/// 坐标转换工具
struct CoordinateConverter {

    // MARK: - Constants

    /// 长半轴
    private static let a: Double = 6378245.0

    /// 扁率
    private static let ee: Double = 0.00669342162296594323

    /// 圆周率
    private static let pi: Double = 3.1415926535897932384626

    // MARK: - Public Methods

    /// WGS-84 坐标转换为 GCJ-02 坐标（火星坐标系）
    /// - Parameter wgsLocation: WGS-84 坐标（GPS 原始坐标）
    /// - Returns: GCJ-02 坐标（中国加密坐标）
    static func wgs84ToGcj02(_ wgsLocation: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let lat = wgsLocation.latitude
        let lon = wgsLocation.longitude

        // 判断是否在中国境内
        if !isInChina(lat: lat, lon: lon) {
            // 不在中国境内，直接返回原坐标
            return wgsLocation
        }

        // 计算偏移量
        var dLat = transformLat(x: lon - 105.0, y: lat - 35.0)
        var dLon = transformLon(x: lon - 105.0, y: lat - 35.0)

        let radLat = lat / 180.0 * pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)

        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi)

        let mgLat = lat + dLat
        let mgLon = lon + dLon

        return CLLocationCoordinate2D(latitude: mgLat, longitude: mgLon)
    }

    /// 批量转换坐标
    /// - Parameter wgsLocations: WGS-84 坐标数组
    /// - Returns: GCJ-02 坐标数组
    static func wgs84ToGcj02(_ wgsLocations: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        return wgsLocations.map { wgs84ToGcj02($0) }
    }

    // MARK: - Private Methods

    /// 判断坐标是否在中国境内（粗略判断）
    private static func isInChina(lat: Double, lon: Double) -> Bool {
        // 中国大陆范围：纬度 3.86 ~ 53.55，经度 73.66 ~ 135.05
        return lon >= 73.66 && lon <= 135.05 && lat >= 3.86 && lat <= 53.55
    }

    /// 纬度转换（内部算法）
    private static func transformLat(x: Double, y: Double) -> Double {
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * pi) + 320.0 * sin(y * pi / 30.0)) * 2.0 / 3.0
        return ret
    }

    /// 经度转换（内部算法）
    private static func transformLon(x: Double, y: Double) -> Double {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0
        return ret
    }
}
