//
//  SpringModalBottomSheet.swift
//  Plan4U_iOS
//
//  Custom elastic spring physics container matching Android SpringModalBottomSheet.kt.
//

import SwiftUI

public struct SpringModalContainer<Content: View>: View {
    @Binding public var isPresented: Bool
    public var isDarkTheme: Bool = false
    public var content: () -> Content

    @State private var offset: CGFloat = 600
    @State private var isAnimating: Bool = false

    public init(
        isPresented: Binding<Bool>,
        isDarkTheme: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self.isDarkTheme = isDarkTheme
        self.content = content
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                // Dimmed Scrim
                Color.black.opacity(0.38)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                    .transition(.opacity)

                // Spring Drawer
                VStack(spacing: 0) {
                    // Drag handle
                    Capsule()
                        .fill(isDarkTheme ? Color(hex: 0x475569) : Color(hex: 0xCBD5E1))
                        .frame(width: 36, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                    content()
                }
                .frame(maxWidth: .infinity)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 28,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 28
                    )
                    .fill(isDarkTheme ? MiodiStaticColors.darkCardBg : Color.white)
                    .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: -4)
                )
                .offset(y: offset)
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            if val.translation.height > 0 {
                                offset = val.translation.height
                            }
                        }
                        .onEnded { val in
                            if val.translation.height > 120 || val.velocity.height > 500 {
                                dismiss()
                            } else {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                                    offset = 0
                                }
                            }
                        }
                )
                .onAppear {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.74)) {
                        offset = 0
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isPresented)
    }

    private func dismiss() {
        MiodiHapticFeedback.lightClick()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            offset = 600
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}
