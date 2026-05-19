//
//  QuickSaleView.swift
//  UIKitPractice
//

import AVFoundation
import Observation
import SwiftUI
import UIKit
import VisionKit

struct QuickSaleScreen: View {
    @Bindable var viewModel: QuickSaleViewModel
    @State private var isCameraPresented = false
    @State private var scannerFieldID = UUID()
    @State private var isHardwareScannerReady = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    scanBanner
                    scannerPanel
                    receiptHeader

                    if viewModel.cartItems.isEmpty {
                        emptyReceiptCard
                    } else {
                        cartList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, viewModel.hasItems ? 126 : 32)
            }
            .scrollIndicators(.hidden)
            .background(SalesColors.background.ignoresSafeArea())

            HardwareScannerField(id: scannerFieldID) { barcode in
                viewModel.processBarcode(barcode)
                scannerFieldID = UUID()
            }
            .id(scannerFieldID)
            .frame(width: 1, height: 1)
            .opacity(0)
            .offset(x: -1000, y: -1000)

            if viewModel.hasItems {
                stickyFooter
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            toastLayer
        }
        .animation(.easeOut(duration: 0.22), value: viewModel.hasItems)
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraScannerOverlay(
                onClose: { isCameraPresented = false },
                onBarcode: { barcode in
                    isCameraPresented = false
                    viewModel.processBarcode(barcode)
                }
            )
        }
        .fullScreenCover(item: $viewModel.checkoutRoute) { route in
            SalesPaymentSetupScreen(
                summary: route.summary,
                onClose: { viewModel.dismissCheckout() },
                onConnectPayment: { viewModel.connectPaymentInfrastructureForDemo() },
                onFinishSale: { viewModel.finishSaleAfterPaymentSetup() }
            )
        }
        .appLocalized()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.tr("Продажа"))
                .font(.system(size: 30, weight: .bold))
                .tracking(-0.3)
                .foregroundStyle(SalesColors.foreground)

            Text(L10n.tr("Сканируйте товары — они появятся в чеке"))
                .font(.system(size: 14))
                .foregroundStyle(SalesColors.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scanBanner: some View {
        Button {
            isCameraPresented = true
        } label: {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 128, height: 128)
                    .offset(x: 142, y: -50)

                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.2))
                        .frame(width: 56, height: 56)
                        .overlay {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr("Сканировать штрих-код"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)

                        Text(L10n.tr("Нажмите для камеры"))
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                    Image(systemName: "camera")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .padding(.leading, 18)
                .padding(.trailing, 16)
                .frame(height: 92)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .background {
                LinearGradient(
                    colors: [SalesColors.primary, Color.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: SalesColors.primary.opacity(0.5), radius: 30, x: 0, y: 10)
        }
        .buttonStyle(ScanBannerButtonStyle())
    }

    private var scannerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                isHardwareScannerReady = true
                scannerFieldID = UUID()
                viewModel.hardwareScannerActivated()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "barcode")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SalesColors.accentForeground)
                        .frame(width: 40, height: 40)
                        .background(SalesColors.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.tr("Сканировать товар по сканеру"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SalesColors.foreground)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        Text(L10n.tr(isHardwareScannerReady ? "Подключите сканер и считайте штрих-код" : "Нажмите, чтобы активировать ввод"))
                            .font(.system(size: 12))
                            .foregroundStyle(SalesColors.mutedForeground)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: isHardwareScannerReady ? "checkmark.circle.fill" : "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isHardwareScannerReady ? SalesColors.success : SalesColors.mutedForeground)
                }
                .padding(12)
                .background(SalesColors.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SalesColors.border, lineWidth: 1)
                }
            }
            .buttonStyle(PlainScaleButtonStyle(scale: 0.98))

            mockScannerTools
        }
    }

    private var mockScannerTools: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.tr("Тест сканирования"))
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(SalesColors.mutedForeground)

                Spacer()

                Button {
                    viewModel.fillMockReceipt()
                } label: {
                    Label(L10n.tr("Заполнить чек"), systemImage: "wand.and.stars")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(SalesColors.primary)
            }

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(viewModel.testProducts) { product in
                        Button {
                            viewModel.mockScan(product)
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 12, weight: .semibold))

                                Text(product.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(SalesColors.foreground)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemFill), in: Capsule())
                        }
                        .buttonStyle(DimmingButtonStyle())
                    }
                }
                .padding(.vertical, 1)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var receiptHeader: some View {
        HStack {
            Text(L10n.tr("ЧЕК"))
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(SalesColors.mutedForeground)

            Spacer()

            if viewModel.hasItems {
                Button(L10n.tr("Очистить")) {
                    viewModel.clearCart()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SalesColors.destructive)
            }
        }
        .padding(.top, 2)
    }

    private var emptyReceiptCard: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemFill))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "bag")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(SalesColors.mutedForeground)
                }

            VStack(spacing: 6) {
                Text(L10n.tr("Чек пуст"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SalesColors.foreground)

                Text(L10n.tr("Отсканируйте первый товар, чтобы начать продажу"))
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(SalesColors.mutedForeground)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .padding(.horizontal, 24)
        .background(SalesColors.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    SalesColors.border,
                    style: StrokeStyle(lineWidth: 1, dash: [7, 6], dashPhase: 0)
                )
        }
    }

    private var cartList: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.cartItems) { item in
                CartItemCard(
                    item: item,
                    onMinus: { viewModel.decrement(item) },
                    onPlus: { viewModel.increment(item) },
                    onDelete: { viewModel.remove(item) }
                )
            }
        }
    }

    private var stickyFooter: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.tr("sales.footer_total"))
                    .font(.system(size: 12))
                    .foregroundStyle(SalesColors.mutedForeground)

                Text(viewModel.totalAmountFormatted)
                    .font(.system(size: 20, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(SalesColors.foreground)

                Text(L10n.format("sales.footer_items_format", viewModel.positionsCount, viewModel.totalQuantity))
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(SalesColors.mutedForeground)
            }
            .frame(width: 132, alignment: .leading)

            Button {
                viewModel.completeSale()
            } label: {
                Label(L10n.tr("Завершить продажу"), systemImage: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(SalesColors.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PlainScaleButtonStyle(scale: 0.98))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(SalesColors.background.opacity(0.85))
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(SalesColors.border)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private var toastLayer: some View {
        if let toast = viewModel.toast {
            SalesToastView(toast: toast)
                .padding(.horizontal, 16)
                .padding(.bottom, viewModel.hasItems ? 112 : 22)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeOut(duration: 0.2), value: toast.id)
        }
    }
}

private struct SalesPaymentSetupScreen: View {
    let summary: SalesCheckoutSummary
    let onClose: () -> Void
    let onConnectPayment: () -> Void
    let onFinishSale: () -> Void

    @State private var isConnected = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    summaryCard
                    requirementCard
                    stepsCard
                    actionArea
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .background(SalesColors.background.ignoresSafeArea())
            .navigationTitle(L10n.tr("sales.checkout.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(SalesColors.foreground)
                            .frame(width: 34, height: 34)
                            .background(Color(.secondarySystemFill), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .appLocalized()
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(SalesColors.accent)
                    .frame(width: 76, height: 76)

                Image(systemName: isConnected ? "checkmark.seal.fill" : "creditcard.and.123")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(isConnected ? SalesColors.success : SalesColors.accentForeground)
            }

            VStack(spacing: 6) {
                Text(isConnected ? L10n.tr("sales.checkout.connected_title") : L10n.tr("sales.checkout.setup_title"))
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(isConnected ? L10n.tr("sales.checkout.connected_subtitle") : L10n.tr("sales.checkout.setup_subtitle"))
                    .font(.system(size: 14))
                    .foregroundStyle(SalesColors.mutedForeground)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.tr("sales.checkout.summary"))
                .font(.system(size: 12, weight: .semibold))
                .tracking(1)
                .foregroundStyle(SalesColors.mutedForeground)

            HStack(spacing: 12) {
                CheckoutMetric(
                    title: L10n.tr("sales.checkout.positions"),
                    value: "\(summary.positionsCount)"
                )
                CheckoutMetric(
                    title: L10n.tr("sales.checkout.quantity"),
                    value: "\(summary.totalQuantity)"
                )
                CheckoutMetric(
                    title: L10n.tr("sales.checkout.total"),
                    value: summary.totalAmountFormatted
                )
            }
        }
        .padding(16)
        .background(SalesColors.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(SalesColors.border, lineWidth: 1)
        }
        .shadow(color: UIChrome.cardShadowColor(for: colorScheme).opacity(0.4), radius: 10, x: 0, y: 4)
    }

    private var requirementCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isConnected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isConnected ? SalesColors.success : SalesColors.warning)
                .frame(width: 36, height: 36)
                .background((isConnected ? SalesColors.success : SalesColors.warning).opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(isConnected ? L10n.tr("sales.checkout.ready_title") : L10n.tr("sales.checkout.required_title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SalesColors.foreground)

                Text(isConnected ? L10n.tr("sales.checkout.ready_message") : L10n.tr("sales.checkout.required_message"))
                    .font(.system(size: 13))
                    .foregroundStyle(SalesColors.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(SalesColors.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(SalesColors.border, lineWidth: 1)
        }
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.tr("sales.checkout.steps_title"))
                .font(.system(size: 15, weight: .semibold))

            CheckoutStepRow(index: 1, title: L10n.tr("sales.checkout.step_qr"), systemImage: "qrcode")
            CheckoutStepRow(index: 2, title: L10n.tr("sales.checkout.step_bank"), systemImage: "building.columns.fill")
            CheckoutStepRow(index: 3, title: L10n.tr("sales.checkout.step_fiscal"), systemImage: "printer.fill")
        }
        .padding(16)
        .background(SalesColors.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(SalesColors.border, lineWidth: 1)
        }
    }

    private var actionArea: some View {
        VStack(spacing: 10) {
            Button {
                if isConnected {
                    onFinishSale()
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isConnected = true
                    }
                    onConnectPayment()
                }
            } label: {
                Label(
                    isConnected ? L10n.tr("sales.checkout.finish_sale") : L10n.tr("sales.checkout.connect_payment"),
                    systemImage: isConnected ? "checkmark" : "link"
                )
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(SalesColors.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PlainScaleButtonStyle(scale: 0.98))

            Button(action: onClose) {
                Text(L10n.tr("sales.checkout.back_to_receipt"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SalesColors.foreground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PlainScaleButtonStyle(scale: 0.98))
        }
        .padding(.top, 4)
    }
}

private struct CheckoutMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SalesColors.mutedForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(SalesColors.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CheckoutStepRow: View {
    let index: Int
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(SalesColors.accentForeground)
                .frame(width: 28, height: 28)
                .background(SalesColors.accent, in: Circle())

            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SalesColors.mutedForeground)
                .frame(width: 22)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SalesColors.foreground)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

private struct CartItemCard: View {
    let item: SalesCartItem
    let onMinus: () -> Void
    let onPlus: () -> Void
    let onDelete: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(SalesColors.accent)
                .frame(width: 56, height: 44)
                .overlay {
                    Text("\(item.quantity)")
                        .font(.system(size: 16, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(SalesColors.accentForeground)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.product.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(SalesColors.foreground)

                Text(L10n.format("sales.stock_left_format", item.remainingStock))
                    .font(.system(size: 12))
                    .monospacedDigit()
                    .foregroundStyle(SalesColors.mutedForeground)
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                CircleIconButton(systemImage: "minus", foreground: SalesColors.foreground, background: Color(.secondarySystemFill), action: onMinus)
                CircleIconButton(systemImage: "plus", foreground: SalesColors.foreground, background: Color(.secondarySystemFill), action: onPlus)
                CircleIconButton(systemImage: "trash", foreground: SalesColors.destructive, background: SalesColors.destructive.opacity(0.1), action: onDelete)
            }
        }
        .padding(12)
        .background(SalesColors.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: UIChrome.cardShadowColor(for: colorScheme).opacity(0.55), radius: 8, x: 0, y: 3)
    }
}

private struct CircleIconButton: View {
    let systemImage: String
    let foreground: Color
    let background: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(foreground)
                .frame(width: 36, height: 36)
                .background(background, in: Circle())
        }
        .buttonStyle(DimmingButtonStyle())
    }
}

private struct SalesToastView: View {
    let toast: SalesToast

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))

            Text(toast.message)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(SalesColors.card, in: Capsule())
        .overlay {
            Capsule()
                .stroke(color.opacity(0.25), lineWidth: 1)
        }
        .shadow(color: UIChrome.cardShadowColor(for: colorScheme), radius: 12, x: 0, y: 5)
    }

    private var color: Color {
        switch toast.style {
        case .success: return SalesColors.success
        case .warning: return SalesColors.warning
        case .destructive: return SalesColors.destructive
        }
    }

    private var icon: String {
        switch toast.style {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .destructive: return "xmark.circle.fill"
        }
    }
}

private struct CameraScannerOverlay: View {
    let onClose: () -> Void
    let onBarcode: (String) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if DataScannerViewController.isSupported {
                BarcodeDataScannerView(onBarcode: onBarcode)
                    .ignoresSafeArea()
            } else {
                Text(L10n.tr("Сканер недоступен на этом устройстве"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            CameraViewfinderOverlay()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 18)
                    .padding(.trailing, 18)
                }

                Spacer()

                Text(L10n.tr("Наведите камеру на штрих-код товара"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.bottom, 50)
            }
        }
    }
}

private struct CameraViewfinderOverlay: View {
    private let frameSize = CGSize(width: 256, height: 160)
    private let cornerRadius: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            let minX = max((proxy.size.width - frameSize.width) / 2, 0)
            let minY = max((proxy.size.height - frameSize.height) / 2, 0)
            let maxX = minX + frameSize.width
            let maxY = minY + frameSize.height

            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.45)
                    .frame(width: proxy.size.width, height: minY)

                Color.black.opacity(0.45)
                    .frame(width: proxy.size.width, height: max(proxy.size.height - maxY, 0))
                    .offset(y: maxY)

                Color.black.opacity(0.45)
                    .frame(width: minX, height: frameSize.height)
                    .offset(y: minY)

                Color.black.opacity(0.45)
                    .frame(width: max(proxy.size.width - maxX, 0), height: frameSize.height)
                    .offset(x: maxX, y: minY)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white, lineWidth: 2)
                    .frame(width: frameSize.width, height: frameSize.height)
                    .offset(x: minX, y: minY)
            }
        }
    }
}

private struct BarcodeDataScannerView: UIViewControllerRepresentable {
    let onBarcode: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: false,
            isHighlightingEnabled: false
        )
        controller.delegate = context.coordinator

        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcode: onBarcode)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onBarcode: (String) -> Void

        init(onBarcode: @escaping (String) -> Void) {
            self.onBarcode = onBarcode
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let barcode = addedItems.compactMap(\.barcodePayload).first else { return }
            onBarcode(barcode)
        }
    }
}

private extension RecognizedItem {
    var barcodePayload: String? {
        if case .barcode(let barcode) = self {
            return barcode.payloadStringValue
        }
        return nil
    }
}

private struct HardwareScannerField: UIViewRepresentable {
    let id: UUID
    let onSubmit: (String) -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .done
        textField.textContentType = .oneTimeCode
        textField.tintColor = .clear
        textField.textColor = .clear
        textField.backgroundColor = .clear
        textField.inputView = UIView(frame: .zero)

        DispatchQueue.main.async {
            textField.becomeFirstResponder()
        }

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.onSubmit = onSubmit
        if !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSubmit: onSubmit)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var onSubmit: (String) -> Void

        init(onSubmit: @escaping (String) -> Void) {
            self.onSubmit = onSubmit
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            let barcode = textField.text ?? ""
            textField.text = ""
            onSubmit(barcode)
            return false
        }
    }
}

private enum SalesColors {
    static let background = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let primary = Color.accentColor
    static let foreground = Color.primary
    static let mutedForeground = Color.secondary
    static let success = Color(.systemGreen)
    static let warning = Color(.systemOrange)
    static let destructive = Color(.systemRed)
    static let accent = Color.accentColor.opacity(0.12)
    static let accentForeground = Color.accentColor
    static let border = Color(.separator).opacity(0.6)
}

private struct ScanBannerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct PlainScaleButtonStyle: ButtonStyle {
    let scale: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct DimmingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
