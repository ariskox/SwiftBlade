//
//  MockJob.swift
//  SwiftBlade
//
//  Created by Aris Koxaras on 19/10/24.
//

import Foundation
@testable import SwiftBlade

actor MockJob: ParallelJob {
    typealias Item = Int

    var items: [Item]
    let canStart: Bool = true

    init(items: [Item]) {
        self.items = items
    }

    func process(_ item: Item) async throws {
        try await Task.sleep(nanoseconds: 10_000)
    }
}
