//
//  GroupView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 2/21/24.
//

import SwiftUI

struct GroupView: View {
    @State var selectedGroup: Group?

    @StateObject var scanReceipt = ScanReceipt()
    @EnvironmentObject var user: UserViewModel
    var body: some View {
        VStack {
            Text(selectedGroup?.group_name ?? "None")            
            if (selectedGroup?.owner_id == user.user_id) {
                Button {
                    // Create Transaction Flow / Camera => Picture
                    // => Upload Data to DB => Display'
                    Task{
                        guard let image = UIImage(named: "Test6") else {
                            print("Error loading Image")
                            return
                        }
                        await scanReceipt.scanReceipt(image: image)
                        await createTransaction()

                    }
                }
            label: {
                Text("Create")
                }
            }
            Spacer()
            BottomToolbar()
                .padding()
        }
        .onAppear {
            print("DISPLAYING GROUP \(user.groups[user.selectedGroupIndex])")
            selectedGroup = user.groups[user.selectedGroupIndex]
        }
    }
    private func createTransaction() async {
        let scannedItems = scanReceipt.receiptItems // Assume these are the scanned receipt items
           let transactionItems = scannedItems.map { Item(priceInCents: Int($0.price * 100), name: $0.name) }
           let newTransaction = Transaction(itemList: transactionItems, name: "New Transaction from Receipt")
            await DatabaseAPI.createTransaction(transactionData: newTransaction, groupID: selectedGroup?.groupID)
       }
}

struct GroupView_Previews: PreviewProvider {
    static var previews: some View {
        GroupView().environmentObject(UserViewModel())
    }
}
