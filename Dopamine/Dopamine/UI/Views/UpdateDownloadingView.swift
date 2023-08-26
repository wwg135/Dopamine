//
//  UpdateDownloadingView.swift
//  Fugu15
//
//  Created by sourcelocation on 12/04/2023.
//

import SwiftUI
import SwiftfulLoadingIndicators

enum UpdateType {
    case environment, regular
}

struct UpdateDownloadingView: View {   
    enum UpdateState {
        case downloading, updating
    }
    
    @State var progressDouble: Double = 0
    var downloadProgress = Progress()

    @State var showButton = true
    @Binding var type: UpdateType?
    @State var updateState: UpdateState = .downloading
    
    var body: some View {
        ZStack {
            if type != nil {
                Color.black
                    .ignoresSafeArea()
                    .opacity(0.6)
                    .transition(.opacity.animation(.spring()))

                VStack {
                    if !showButton {
                        VStack(spacing: 150) {
                            VStack(spacing: 10) {
                                Spacer()
                                Text(updateState != .updating ? NSLocalizedString("Update_Status_Downloading", comment: "") : NSLocalizedString("Update_Status_Installing", comment: ""))
                                    .font(.title2)
                                    .multilineTextAlignment(.center)
                                    .drawingGroup()
                                Text(updateState == .downloading ? NSLocalizedString("Update_Status_Subtitle_Please_Wait", comment: "") : NSLocalizedString("Update_Status_Subtitle_Restart_Soon", comment: ""))
                                    .opacity(0.5)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, 32)
                            }
                            .animation(.spring(), value: updateState)
                            .frame(height: 225)
                        }
                        ZStack {
                            ZStack {
                                Text("\(Int(progressDouble * 100))%")
                                    .font(.title)
                                    .opacity(updateState == .downloading ? 1 : 0)
                                if type != nil {
                                    LoadingIndicator(animation: .circleRunner, color: .white, size: .medium, speed: .normal)
                                        .opacity(updateState == .updating ? 1 : 0)
                                }
                            }
                            Circle()
                                .stroke(
                                    Color.white.opacity(0.1),
                                    lineWidth: updateState == .downloading ? 8 : 4
                                )
                                .animation(.spring(), value: updateState)
                            Circle()
                                .trim(from: 0, to: progressDouble)
                                .stroke(
                                    Color.white,
                                    style: StrokeStyle(
                                        lineWidth: updateState == .downloading ? 8 : 0,
                                        lineCap: .round
                                    )
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut, value: progressDouble)
                                .animation(.spring(), value: updateState)
                        }
                        .frame(height: 128)
                        .padding(32)
                    }
                }
            }
        }
        .foregroundColor(.white)
    }

struct UpdateDownloadingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
                .opacity(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            UpdateDownloadingView(type: .constant(.regular))
        }
    }
}
