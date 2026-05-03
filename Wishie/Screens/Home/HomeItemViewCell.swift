//
//  HomeItemViewCell.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 26/4/26.
//

import SwiftUI

struct HomeItemViewCell: View {
    var item: (WishlistModel, UserModel)
    var body: some View {
        let itemPicked = item.0.items.filter({ $0.isPicked })
        VStack {
            HStack {
                Text(item.0.name)
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.leading)
                    .font(.wishies(.bold, 17))
                Spacer()
                Text("\(item.1.firstName) \(item.1.lastName)")
                    .foregroundStyle(Color.black)
                    .font(.wishies(.regular, 15))
                    .truncationMode(.tail)
                Image("user")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
            }
            HStack(alignment: .top) {
                    Text(item.0.description)
                        .font(.wishies(.italic, 14))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                
                
                Spacer()
                VStack {
                    if item.0.items.count > 0 {
                        let progress = Double(itemPicked.count) / Double(item.0.items.count)
                        GiftProgressView(progress: progress)
                    }
                }
                .frame(maxWidth: 100)
            }
            HStack {
                Text("end date: \(item.0.dueDate.toShortDateString())")
                    .font(.wishies(.regular, 14))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity,alignment: .leading)
                Group {
                    if item.0.items.count > 0 {
                        Text("\(itemPicked.count)/\(item.0.items.count) gifts")
                            .font(.wishies(.regular, 14))
                            .foregroundStyle(Color.darkGrey)
                    } else {
                        Text("0 gift")
                            .font(.wishies(.regular, 14))
                            .foregroundStyle(Color.darkGrey)
                    }
                }
                .padding(.trailing)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.sunset).opacity(0.5)
        }
    }
}

#Preview {
    let item1 = WishlistItem(
        id: "1",
        name: "Item 1",
        description: "",
        image: "",
        pickedUserId: "",
        isPicked: false,
        localImage: nil,
        itemLink: ""
    )
    let item2 = WishlistItem(
        id: "2",
        name: "Item 2",
        description: "",
        image: "",
        pickedUserId: "",
        isPicked: false,
        localImage: nil,
        itemLink: ""
    )
    let wishListModel = WishlistModel(
        id: "1",
        name: "Test",
        description: "This is a test des",
        dueDate: Date(),
        items: [item1, item2],
        themeColor: nil,
        userCreateId: "1",
        members: [:]
    )
    let userModel = UserModel()
    HomeItemViewCell(item: (wishListModel, userModel))
}
