//
//  MapTabView.swift
//  Earthlord
//
//  地图页面：显示地图、用户位置，处理定位权限
//

import SwiftUI
import MapKit

struct MapTabView: View {
    // MARK: - Properties

    /// 定位管理器
    @StateObject private var locationManager = LocationManager()

    /// 用户位置
    @State private var userLocation: CLLocationCoordinate2D?

    /// 是否已定位到用户
    @State private var hasLocatedUser = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // 地图层
            if locationManager.isAuthorized {
                // 已授权：显示地图
                MapViewRepresentable(
                    userLocation: $userLocation,
                    hasLocatedUser: $hasLocatedUser
                )
                .ignoresSafeArea()
            } else {
                // 未授权：显示占位背景
                ApocalypseTheme.background
                    .ignoresSafeArea()
            }

            // 顶部信息栏
            VStack {
                topInfoBar
                Spacer()
            }

            // 权限请求提示卡片（未授权时显示）
            if !locationManager.isAuthorized && !locationManager.isDenied {
                VStack {
                    Spacer()
                    permissionRequestCard
                    Spacer()
                }
            }

            // 权限被拒绝提示卡片
            if locationManager.isDenied {
                VStack {
                    Spacer()
                    permissionDeniedCard
                    Spacer()
                }
            }

            // 右下角定位按钮
            if locationManager.isAuthorized {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        locationButton
                    }
                }
            }
        }
        .onAppear {
            // 页面出现时检查权限状态
            checkLocationPermission()
        }
    }

    // MARK: - Subviews

    /// 顶部信息栏
    private var topInfoBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("地球新主")
                    .font(.headline)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                if let location = userLocation {
                    // 显示坐标
                    Text("坐标: \(String(format: "%.6f", location.latitude)), \(String(format: "%.6f", location.longitude))")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                } else {
                    Text("正在定位...")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.warning)
                }
            }

            Spacer()

            // GPS 信号图标
            Image(systemName: locationManager.userLocation != nil ? "location.fill" : "location.slash.fill")
                .foregroundColor(locationManager.userLocation != nil ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
                .font(.title3)
        }
        .padding()
        .background(
            ApocalypseTheme.cardBackground.opacity(0.95)
        )
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    /// 权限请求卡片
    private var permissionRequestCard: some View {
        VStack(spacing: 20) {
            // 图标
            Image(systemName: "location.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.primary)

            // 标题
            Text("需要定位权限")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 说明
            Text("《地球新主》需要获取您的位置来显示您在末日世界中的坐标，帮助您探索和圈定领地。")
                .font(.body)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // 授权按钮
            Button(action: {
                locationManager.requestPermission()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("允许定位")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ApocalypseTheme.primary)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding(30)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 20)
        .padding(.horizontal, 30)
    }

    /// 权限被拒绝卡片
    private var permissionDeniedCard: some View {
        VStack(spacing: 20) {
            // 图标
            Image(systemName: "location.slash.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.danger)

            // 标题
            Text("定位权限被拒绝")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 说明
            Text("请在系统设置中允许《地球新主》访问您的位置信息。")
                .font(.body)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // 前往设置按钮
            Button(action: {
                openSettings()
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("前往设置")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ApocalypseTheme.primary)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding(30)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 20)
        .padding(.horizontal, 30)
    }

    /// 右下角定位按钮
    private var locationButton: some View {
        Button(action: {
            centerToUserLocation()
        }) {
            Image(systemName: "location.fill")
                .font(.title3)
                .foregroundColor(.white)
                .padding(16)
                .background(ApocalypseTheme.primary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8)
        }
        .padding(.trailing, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Private Methods

    /// 检查定位权限
    private func checkLocationPermission() {
        if locationManager.isAuthorized {
            // 已授权，开始定位
            locationManager.startUpdatingLocation()
        } else if locationManager.authorizationStatus == .notDetermined {
            // 未决定，请求权限
            print("📍 首次打开，准备请求定位权限")
        }
    }

    /// 居中到用户位置
    private func centerToUserLocation() {
        // 这里只是触发重新定位，实际居中逻辑在 MapViewRepresentable 中
        hasLocatedUser = false
        print("🎯 用户点击定位按钮")
    }

    /// 打开系统设置
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    MapTabView()
}
