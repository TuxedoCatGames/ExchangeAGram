//
//  FilterViewController.swift
//  ExchangeAGram
//
//  Created by Bob Keifer on 12/23/14.
//  Copyright (c) 2014 BitFountain. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var feedItem: FeedItem!
    var collectionView: UICollectionView!
    var context: CIContext = CIContext(options: nil)
    var filters: [CIFilter] = []
    
    let placeholderImage = UIImage(named: "Placeholder")
    let tmp = NSTemporaryDirectory()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 150.0, height: 150.0)
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.whiteColor()
        
        collectionView.registerClass(FilterCell.self, forCellWithReuseIdentifier: "Cell")
        
        self.view.addSubview(collectionView)
        
        filters = photoFilters()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Collection View
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return filters.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell: FilterCell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as FilterCell
        
        //if cell.imageView.image == nil {
            
            cell.imageView.image = placeholderImage
            
            let filterQueue:dispatch_queue_t = dispatch_queue_create("filter queue", nil)
            dispatch_async(filterQueue, { () -> Void in
                
                //let filteredImage = self.filteredImageFromImage(self.feedItem.thumbnail, filter: self.filters[indexPath.row])
                let filteredImage = self.imageFromCache(indexPath.row)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    cell.imageView.image = filteredImage
                })
                
            })
        //}
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let filteredImage = self.filteredImageFromImage(feedItem.image, filter: filters[indexPath.row])
        let imageData = UIImageJPEGRepresentation(filteredImage, 1.0)
        feedItem.image = imageData
        let thumnailData = UIImageJPEGRepresentation(filteredImage, 0.1)
        feedItem.thumbnail = thumnailData
        
        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - Filters
    
    func photoFilters() -> [CIFilter] {
        
        let blur = CIFilter(name: "CIGaussianBlur")
        let instant = CIFilter(name: "CIPhotoEffectInstant")
        let noir = CIFilter(name: "CIPhotoEffectNoir")
        let transefer = CIFilter(name: "CIPhotoEffectTransfer")
        let unsharpen = CIFilter(name: "CIUnsharpMask")
        let monochrome = CIFilter(name: "CIColorMonochrome")
        
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls.setValue(0.5, forKey: kCIInputSaturationKey)
        
        let sepia = CIFilter(name: "CISepiaTone")
        sepia.setValue(0.7, forKey: kCIInputIntensityKey)
        
        let colorClamp = CIFilter(name: "CIColorClamp")
        colorClamp.setValue(CIVector(x: 0.9, y: 0.9, z: 0.9, w: 0.9), forKey: "inputMaxComponents")
        colorClamp.setValue(CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0.2), forKey: "inputMinComponents")
        
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite.setValue(sepia.outputImage, forKey: kCIInputImageKey)
        
        let vignette = CIFilter(name: "CIVignette")
        vignette.setValue(composite.outputImage, forKey: kCIInputImageKey)
        vignette.setValue(0.7 * 2, forKey: kCIInputIntensityKey)
        vignette.setValue(0.7 * 30, forKey: kCIInputRadiusKey)
        
        return [blur, instant, noir, transefer, unsharpen, monochrome, colorControls, sepia, colorClamp, composite, vignette]
    }
    
    func filteredImageFromImage(imageData: NSData, filter: CIFilter) -> UIImage {
        
        let originalImage = CIImage(data: imageData)
        filter.setValue(originalImage, forKey: kCIInputImageKey)
        
        let filteredImage: CIImage = filter.outputImage
        let extent = filteredImage.extent()
        let cgImage: CGImageRef = context.createCGImage(filteredImage, fromRect: extent)
        let finalImage = UIImage(CGImage: cgImage)
        
        return finalImage!
    }
    
    // MARK: - Caching
    
    func cacheImage(imageNumber: Int) {
        
        let fileName = "\(imageNumber)"
        let path = tmp.stringByAppendingPathComponent(fileName)
        
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            
            let data = self.feedItem.thumbnail
            let filter = self.filters[imageNumber]
            let image = filteredImageFromImage(data, filter: filter)
            UIImageJPEGRepresentation(image, 1.0).writeToFile(path, atomically: true)
        }
    }
    
    func imageFromCache(imageNumber: Int) -> UIImage {
        
        let fileName = "\(imageNumber)"
        let path = tmp.stringByAppendingPathComponent(fileName)
        
        var image: UIImage
        
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            
            self.cacheImage(imageNumber)
        }
        
        image = UIImage(contentsOfFile: path)!
        return image
    }
}
