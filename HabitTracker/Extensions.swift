//
//  Extensions.swift
//  HabitTracker
//
//  Created by Vineeth  Reddy on 28/11/25.
//

import SwiftUI

extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
        }
    }
}
