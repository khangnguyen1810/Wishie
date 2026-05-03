//
//  CreateWishListScreen.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 13/12/25.
//

import SwiftUI

struct CreateWishListScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var progressTabIndex: Int = 0
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var dueDate: Date = Date()
    var body: some View {
        BaseWishieScreen {
            TopAppBar {
                Circle()
                    .fill(.lightYellow)
                    .frame(width: 50, height: 50)
                    .overlay(content: {
                        Image("back_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                    })
                    .onTapGesture {
                        dismiss()
                    }
                    .padding(.trailing, 10)
            } center: {
                Text("Create new wishlist")
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(.black)
            }
        } content: {
            VStack {
                stepProgress()
                    .padding(.top,20)
                    .padding(.bottom,50)
                informationInputsPage1()
                Spacer()
                Button {
                    if (progressTabIndex < 3) {
                        progressTabIndex += 1
                    } else {
                        // Create wishlist
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.lightYellow)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .overlay {
                            Text("Next step")
                                .font(.wishies(.bold, 20))
                                .foregroundStyle(.black)
                        }
                }
                .padding(.bottom, 50)
                .padding(.horizontal,20)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    @ViewBuilder
    func stepProgress() -> some View {
        HStack(spacing: 0) {
            circleStepItem(index: 0, step: "1")
            Rectangle()
                .fill(.black)
                .frame(width: UIScreen.main.bounds.width * 0.2, height: 2)
            circleStepItem(index: 1, step: "2")
            Rectangle()
                .fill(.black)
                .frame(width: UIScreen.main.bounds.width * 0.2, height: 2)
            circleStepItem(index: 2, step: "3")
        }
    }
    @ViewBuilder
    func circleStepItem(index: Int,step: String) -> some View {
        Circle()
            .fill(index == progressTabIndex ? .wishiePink : .lightYellow)
            .frame(width: 50, height: 50)
            .overlay(content: {
                Text(step)
                    .font(.wishies(.regular, 15))
            })
    }
    
    @ViewBuilder
    func informationInputsPage1() -> some View {
        TextField("Wishlist name", text: $name)
            .font(.wishies(.regular, 17))
            .padding(.horizontal,15)
            .textInputAutocapitalization(.never)
            .background {
                RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                    .frame(height: 56)
            }
            .padding(.bottom,30)
        ZStack(alignment: .topLeading) {
            VStack(alignment: .trailing, spacing: 4) {
                TextEditor(text: $description)
                    .font(.wishies(.regular, 17))
                    .padding(10)
                    .frame(maxHeight: 100)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.lightYellow)
                    )
                    .onChange(of: description) { _, newValue in
                        if newValue.count > 200 {
                            description = String(newValue.prefix(200))
                        }
                    }
                
                Text("\(description.count)/300")
                    .font(.caption)
                    .foregroundColor(description.count == 300 ? .red : .gray)
            }
            if description == "" {
                Text("Description")
                    .font(.wishies(.regular, 17))
                    .foregroundColor(.lightGrey)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
            }
        }
        .padding(.bottom,20)
        DateInputView(date: $dueDate)
    }
}
