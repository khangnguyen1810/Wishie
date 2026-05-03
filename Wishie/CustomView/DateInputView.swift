//
//  BirthdayInputView.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 1/12/25.
//

import SwiftUI
struct DateInputView: View {
    @State private var dateOfBirth = Date()
    @State private var showPicker = false
    
    private var day: String {
        let day = Calendar.current.component(.day, from: dateOfBirth)
        return String(format: "%02d", day)
    }
    private var month: String {
        let month = Calendar.current.component(.month, from: dateOfBirth)
        return String(format: "%02d", month)
    }
    private var year: String {
        let year = Calendar.current.component(.year, from: dateOfBirth)
        return "\(year)"
    }
    @Binding var date: Date
    var combinedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.date(from: "\(day)/\(month)/\(year)")
    }
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                dateOfBirthField(placeHolder: "Date", text: day)
                dateOfBirthField(placeHolder: "Month", text: month)
                dateOfBirthField(placeHolder: "Year", text: year)
            }
            .onTapGesture {
                showPicker = true
            }
            .sheet(isPresented: $showPicker) {
                VStack {
                    DatePicker("Select your date of birth",
                               selection: $dateOfBirth,
                               displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    
                    Button(action: {
                        date = combinedDate ?? Date()
                        showPicker = false
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                            Text("Confirmed")
                                .font(.wishies(.bold, 20))
                                .foregroundStyle(.lightYellow)
                        }
                        .padding()
                    }
                }
                .presentationDetents([.fraction(0.33)])
                .presentationDragIndicator(.visible)
            }
        }
    }
    private func dateOfBirthField(placeHolder: String, text: String) -> some View {
        VStack {
            Text(placeHolder)
                .font(.wishies(.bold, 17))
            Text(text)
                .font(.wishies(.regular, 18))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.lightYellow))
                .cornerRadius(10)
        }
    }
}
