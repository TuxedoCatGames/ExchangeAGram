//
//  FeedItem.swift
//  ExchangeAGram
//
//  Created by Bob Keifer on 12/23/14.
//  Copyright (c) 2014 BitFountain. All rights reserved.
//

import Foundation
import CoreData

@objc (FeedItem)
class FeedItem: NSManagedObject {

    @NSManaged var caption: String
    @NSManaged var image: NSData

}
