//
//  FilterView.swift
//  Agro Store
//
//  Created by Roman Furtuna on 8/7/25.
//

import SwiftUI

struct FilterView: View {
    @Binding var selectedCategory: ProductCategory?
    @Binding var sortOption: SortOption
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempCategory: ProductCategory?
    @State private var tempSortOption: SortOption
    @State private var priceRange: ClosedRange<Double> = 0...100
    @State private var isOrganicOnly = false
    @State private var maxDistance: Double = 50
    
    init(selectedCategory: Binding<ProductCategory?>, sortOption: Binding<SortOption>) {
        self._selectedCategory = selectedCategory
        self._sortOption = sortOption
        self._tempCategory = State(initialValue: selectedCategory.wrappedValue)
        self._tempSortOption = State(initialValue: sortOption.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Button(action: { tempCategory = nil }) {
                        HStack {
                            Text("All Categories")
                            Spacer()
                            if tempCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    ForEach(ProductCategory.allCases, id: \.self) { category in
                        Button(action: { tempCategory = category }) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                
                                Text(category.displayName)
                                
                                Spacer()
                                
                                if tempCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section("Sort By") {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: { tempSortOption = option }) {
                            HStack {
                                Text(option.displayName)
                                Spacer()
                                if tempSortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section("Price Range") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("$\(Int(priceRange.lowerBound))")
                            Spacer()
                            Text("$\(Int(priceRange.upperBound))")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        RangeSlider(range: $priceRange, bounds: 0...200)
                    }
                }
                
                Section("Preferences") {
                    Toggle("Organic Only", isOn: $isOrganicOnly)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Maximum Distance")
                            Spacer()
                            Text("\(Int(maxDistance)) km")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $maxDistance, in: 5...100, step: 5)
                    }
                }
                
                Section {
                    Button("Reset Filters") {
                        resetFilters()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func applyFilters() {
        selectedCategory = tempCategory
        sortOption = tempSortOption
        // In a real app, you'd also apply price range, organic filter, and distance
    }
    
    private func resetFilters() {
        tempCategory = nil
        tempSortOption = .newest
        priceRange = 0...100
        isOrganicOnly = false
        maxDistance = 50
    }
}

struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Active range
                Rectangle()
                    .fill(Color.green)
                    .frame(
                        width: activeRangeWidth(in: geometry.size.width),
                        height: 4
                    )
                    .cornerRadius(2)
                    .offset(x: lowerThumbOffset(in: geometry.size.width))
                
                // Lower thumb
                Circle()
                    .fill(Color.green)
                    .frame(width: 20, height: 20)
                    .offset(x: lowerThumbOffset(in: geometry.size.width))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                updateLowerBound(for: value, in: geometry.size.width)
                            }
                    )
                
                // Upper thumb
                Circle()
                    .fill(Color.green)
                    .frame(width: 20, height: 20)
                    .offset(x: upperThumbOffset(in: geometry.size.width))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                updateUpperBound(for: value, in: geometry.size.width)
                            }
                    )
            }
        }
        .frame(height: 20)
    }
    
    private func lowerThumbOffset(in width: CGFloat) -> CGFloat {
        let percentage = (range.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        return percentage * (width - 20)
    }
    
    private func upperThumbOffset(in width: CGFloat) -> CGFloat {
        let percentage = (range.upperBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        return percentage * (width - 20)
    }
    
    private func activeRangeWidth(in width: CGFloat) -> CGFloat {
        let lowerPercentage = (range.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        let upperPercentage = (range.upperBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        return (upperPercentage - lowerPercentage) * (width - 20)
    }
    
    private func updateLowerBound(for value: DragGesture.Value, in width: CGFloat) {
        let percentage = max(0, min(1, value.location.x / (width - 20)))
        let newValue = bounds.lowerBound + percentage * (bounds.upperBound - bounds.lowerBound)
        let clampedValue = min(newValue, range.upperBound - 1)
        range = clampedValue...range.upperBound
    }
    
    private func updateUpperBound(for value: DragGesture.Value, in width: CGFloat) {
        let percentage = max(0, min(1, value.location.x / (width - 20)))
        let newValue = bounds.lowerBound + percentage * (bounds.upperBound - bounds.lowerBound)
        let clampedValue = max(newValue, range.lowerBound + 1)
        range = range.lowerBound...clampedValue
    }
}

#Preview {
    FilterView(selectedCategory: .constant(nil), sortOption: .constant(.newest))
}
