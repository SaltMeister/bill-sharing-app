//
//  TransactionView.swift
//  reciept bill splitter
//
//  Created by Josh Vu on 3/11/24.
//

import SwiftUI

struct TransactionView: View {
    @EnvironmentObject var user: UserViewModel
    
    var body: some View {
        Button("Complete Transaction") {
            Task {
                await DatabaseAPI.toggleGroupTransactionsCompletion(groupID: user.groups_id?[user.selectedGroupIndex] ?? "", completion: true)
            }
        }
    }
}

#Preview {
    TransactionView()
}
