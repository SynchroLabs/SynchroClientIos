//
//  iOSWrapPanelWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSWrapPanelWrapper");

// http://docs.xamarin.com/guides/ios/user_interface/introduction_to_collection_views/
//
// http://forums.xamarin.com/discussion/11274/how-to-setup-uicollectionview-datasource
//
// https://github.com/xamarin/monotouch-samples/tree/master/SimpleCollectionView/SimpleCollectionView
//

private var wrapPanelCellID = String("WrapPanelCell");

public class WrapPanelCell : UICollectionViewCell
{
    public override init(frame: CGRect)
    {
        super.init(frame: frame);
        
        // BackgroundView = new UIView { BackgroundColor = UIColor.Orange };
        // SelectedBackgroundView = new UIView { BackgroundColor = UIColor.Green };
        //
        // Useful for layout debug:
        //
        // contentView.layer.borderColor = UIColor.lightGrayColor().CGColor;
        // contentView.layer.borderWidth = 2.0;
        // contentView.backgroundColor = UIColor.whiteColor();
    }

    required public init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateView(controlWrapper: iOSControlWrapper)
    {
        if (self.contentView.subviews.count > 0)
        {
            contentView.subviews[0].removeFromSuperview();
        }
        contentView.addSubview(controlWrapper.control!);
    }
}

public class WrapPanelCollectionViewSource : NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    var controlWrappers = [iOSControlWrapper]();

    var _itemHeight: CGFloat = 0;
    public var itemHeight: CGFloat { get { return _itemHeight; } set(value) { _itemHeight = value; } }
    
    var _itemWidth: CGFloat = 0;
    public var itemWidth: CGFloat { get { return _itemWidth; } set(value) { _itemWidth = value; } }

    public override init()
    {
        super.init();
    }
    
    // UICollectionViewDataSource method
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        return 1;
    }
    
    // UICollectionViewDataSource method
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection: Int) -> Int
    {
        return controlWrappers.count;
    }
    
    // UICollectionViewDataSource method
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(wrapPanelCellID, forIndexPath: indexPath) as! WrapPanelCell;
    
        // logger.Info("Updating cell {0} with frame: {1}", indexPath.Item, cell.Frame);
    
        var controlWrapper = controlWrappers[indexPath.row];
        cell.updateView(controlWrapper);
    
        return cell;
    }
    
    public func shouldHighlightItem(collectionView: UICollectionView, indexPath: NSIndexPath) -> Bool
    {
        return false;
    }
    
    // UICollectionViewDelegateFlowLayout
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return self.sizeForItemAtIndexPath(indexPath);
    }

    
    public func sizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize
    {
        var controlWrapper = controlWrappers[indexPath.row];
        var controlSize = controlWrapper.control!.frame.size;
        if (_itemHeight > 0)
        {
            controlSize.height = _itemHeight;
        }
        else
        {
            controlSize.height += CGFloat(controlWrapper.marginTop + controlWrapper.marginBottom);
        }
        if (_itemWidth > 0)
        {
            controlSize.width = _itemWidth;
        }
        else
        {
            controlSize.width += CGFloat(controlWrapper.marginLeft + controlWrapper.marginRight);
        }
        return controlSize;
    }
    
    public func itemAtIndexPath(indexPath: NSIndexPath) -> iOSControlWrapper
    {
        return controlWrappers[indexPath.row];
    }
}

public class WrapPanelCollectionViewLayout : UICollectionViewFlowLayout
{
    var _source: WrapPanelCollectionViewSource;
    
    public init(source: WrapPanelCollectionViewSource )
    {
        _source = source;
        super.init();
    }

    required public init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var itemHeight: CGFloat
    {
        get { return _source.itemHeight; }
        set(value)
        {
            _source.itemHeight = value;
            self.invalidateLayout();
        }
    }
    
    public var itemWidth: CGFloat
    {
        get { return _source.itemWidth; }
        set(value)
        {
            _source.itemWidth = value;
            self.invalidateLayout();
        }
    }
    
    func positionLineElements(lineContents: [UICollectionViewLayoutAttributes], linePosition: CGFloat, lineThickness: CGFloat)
    {
        logger.debug("Positioning line with \(lineContents.count) elements, position: \(linePosition), thickness: \(lineThickness)");
        var lineLength: CGFloat = 0;
    
        for lineMember in lineContents
        {
            var controlWrapper = _source.itemAtIndexPath(lineMember.indexPath);
            var allocatedSize = _source.sizeForItemAtIndexPath(lineMember.indexPath);
            var actualSize = controlWrapper.control!.frame.size;
            
            var x: CGFloat;
            var y: CGFloat;
            
            if (self.scrollDirection == UICollectionViewScrollDirection.Vertical)
            {
                // Vertical scroll means horizontal layout...
                //
                if (controlWrapper.horizontalAlignment == HorizontalAlignment.Left)
                {
                    x = lineLength + CGFloat(controlWrapper.marginLeft);
                }
                else if (controlWrapper.horizontalAlignment == HorizontalAlignment.Right)
                {
                    x = lineLength + allocatedSize.width - (actualSize.width + CGFloat(controlWrapper.marginRight));
                }
                else // HorizontalAlignment.Center - default
                {
                    x = lineLength + ((allocatedSize.width - actualSize.width) / 2);
                }
                lineLength += allocatedSize.width;
        
                if (controlWrapper.verticalAlignment == VerticalAlignment.Top)
                {
                    y = linePosition + CGFloat(controlWrapper.marginTop);
                }
                else if (controlWrapper.verticalAlignment == VerticalAlignment.Bottom)
                {
                    y = linePosition + lineThickness - (actualSize.height + CGFloat(controlWrapper.marginBottom));
                }
                else // VerticalAlignment.Center - default
                {
                    y = linePosition + ((lineThickness - actualSize.height) / 2);
                }
            }
            else  // UICollectionViewScrollDirection.Horizontal;
            {
                // Horizontal scroll means vertical layout...
                //
                if (controlWrapper.horizontalAlignment == HorizontalAlignment.Left)
                {
                    x = linePosition + CGFloat(controlWrapper.marginLeft);
                }
                else if (controlWrapper.horizontalAlignment == HorizontalAlignment.Right)
                {
                    x = linePosition + lineThickness - (actualSize.width + CGFloat(controlWrapper.marginRight));
                }
                else // HorizontalAlignment.Center - default
                {
                    x = linePosition + ((lineThickness - actualSize.width) / 2);
                }
        
                if (controlWrapper.verticalAlignment == VerticalAlignment.Top)
                {
                    y = lineLength + CGFloat(controlWrapper.marginTop);
                }
                else if (controlWrapper.verticalAlignment == VerticalAlignment.Bottom)
                {
                    y = lineLength + allocatedSize.height - (actualSize.height + CGFloat(controlWrapper.marginBottom));
                }
                else // VerticalAlignment.Center - default
                {
                    y = lineLength + ((allocatedSize.height - actualSize.height) / 2);
                }
                lineLength += allocatedSize.height;
            }
        
            var frame = lineMember.frame;
            frame.x = x;
            frame.y = y;
            lineMember.frame = frame;
            
            logger.debug("Positioned lineMember at \(frame)");
        }
    }
    
    // We're going to take advantage of the fact that the UICollectionViewFlowLayout will take care of organizing
    // the items into "lines" (rows/columns as appropriate).  We then just process and lay out the line elements
    // to position each element appropriately given its margins and alignment.
    //
    public override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? // [UICollectionViewLayoutAttributes]
    {
        logger.debug("LayoutAttributesForElementsInRect: \(rect)");
        var attributesArray = super.layoutAttributesForElementsInRect(rect) as! [UICollectionViewLayoutAttributes];
        
        var lineContents = [UICollectionViewLayoutAttributes]();
        
        var lineLength: CGFloat = 0;
        var linePosition: CGFloat = 0;
        var lineThickness: CGFloat = 0;
        
        for attributes in attributesArray
        {
            if (attributes.representedElementKind == nil)
            {
                attributes.frame = self.layoutAttributesForItemAtIndexPath(attributes.indexPath).frame;
                
                if (self.scrollDirection == UICollectionViewScrollDirection.Vertical)
                {
                    // Vertical scroll means horizontal layout...
                    //
                    if (attributes.frame.x < (lineLength - 1)) // Make sure it's enough less that it's not a rounding error
                    {
                        // New line...
                        //
                        if (lineContents.count > 0)
                        {
                            self.positionLineElements(lineContents, linePosition: linePosition, lineThickness: lineThickness);
                            lineContents.removeAll();
                        }
    
                        linePosition = attributes.frame.y;
                        lineThickness = attributes.frame.height;
                    }
                    else
                    {
                        // Continuation of current line...
                        //
                        linePosition = min(linePosition, attributes.frame.y);
                        lineThickness = max(lineThickness, attributes.frame.height);
                    }
    
                    lineLength = attributes.frame.x + attributes.frame.width;
                }
                else  // UICollectionViewScrollDirection.Horizontal;
                {
                    // Horizontal scroll means vertical layout...
                    //
                    if (attributes.frame.y < (lineLength - 1)) // Make sure it's enough less that it's not a rounding error
                    {
                        // New line...
                        //
                        if (lineContents.count > 0)
                        {
                            self.positionLineElements(lineContents, linePosition: linePosition, lineThickness: lineThickness);
                            lineContents.removeAll();
                        }
                        
                        linePosition = attributes.frame.x;
                        lineThickness = attributes.frame.width;
                    }
                    else
                    {
                        // Continuation of current line...
                        //
                        linePosition = min(linePosition, attributes.frame.x);
                        lineThickness = max(lineThickness, attributes.frame.width);
                    }
                    
                    lineLength = attributes.frame.y + attributes.frame.height;
                }
    
                lineContents.append(attributes);
            }
        }
        
        self.positionLineElements(lineContents, linePosition: linePosition, lineThickness: lineThickness);
        lineContents.removeAll();
        
        return attributesArray;
    }
}

public class PaddingThicknessSetter : ThicknessSetter
{
    var _layout: UICollectionViewFlowLayout;
    
    public init(layout: UICollectionViewFlowLayout)
    {
        _layout = layout;
    }
    
    public func setThickness(thickness: Double)
    {
        var insets = _layout.sectionInset;
        insets.left = CGFloat(thickness);
        insets.top = CGFloat(thickness);
        insets.right = CGFloat(thickness);
        insets.bottom = CGFloat(thickness);
        _layout.sectionInset = insets;
    }

    public func setThicknessLeft(thickness: Double)
    {
        var insets = _layout.sectionInset;
        insets.left = CGFloat(thickness);
        _layout.sectionInset = insets;
    }
    
    public func setThicknessTop(thickness: Double)
    {
        var insets = _layout.sectionInset;
        insets.top = CGFloat(thickness);
        _layout.sectionInset = insets;
    }
    
    public func setThicknessRight(thickness: Double)
    {
        var insets = _layout.sectionInset;
        insets.right = CGFloat(thickness);
        _layout.sectionInset = insets;
    }
    
    public func setThicknessBottom(thickness: Double)
    {
        var insets = _layout.sectionInset;
        insets.bottom = CGFloat(thickness);
        _layout.sectionInset = insets;
    }
}

public class WrapPanelCollectionView : UICollectionView
{
    var _controlWrapper: iOSControlWrapper;
    
    public init(controlWrapper: iOSControlWrapper, layout: UICollectionViewLayout)
    {
        _controlWrapper = controlWrapper;
        super.init(frame: CGRect(), collectionViewLayout: layout);
        self.backgroundColor = UIColor.clearColor(); // UICollectionView background defaults to Black
    }

    required public init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews()
    {
        super.layoutSubviews();
        
        if let layout = self.collectionViewLayout as? WrapPanelCollectionViewLayout
        {
            var viewSource = self.dataSource as! WrapPanelCollectionViewSource;
            
            var frameSize = self.frame.size;
            
            if (layout.scrollDirection == UICollectionViewScrollDirection.Horizontal)
            {
                // Vertical wrapping (width may vary based on contents, height must be explicit)
                //
                if (_controlWrapper.frameProperties.widthSpec == SizeSpec.WrapContent)
                {
                    frameSize.width = self.contentSize.width;
                }
            }
            else
            {
                // Horizontal wrapping (height may vary based on contents, width must be explicit)
                //
                if (_controlWrapper.frameProperties.heightSpec == SizeSpec.WrapContent)
                {
                    frameSize.height = self.contentSize.height;
                }
            }
        
            if ((frameSize.width != self.frame.width) || (frameSize.height != self.frame.height))
            {
                var frame = self.frame;
                frame.size = frameSize;
                self.frame = frame;
                /*
                if (self.superview != nil)
                {
                    self.superview!.setNeedsLayout();
                }
                */
            }
        }
    }
}

public class iOSWrapPanelWrapper : iOSControlWrapper
{
    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating wrappanel element");
        super.init(parent: parent, bindingContext: bindingContext);
        
        var source = WrapPanelCollectionViewSource();
        var layout = WrapPanelCollectionViewLayout(source: source);
        var view = WrapPanelCollectionView(controlWrapper: self, layout: layout);
        view.delegate = source;
        
        self._control = view;
        
        processElementDimensions(controlSpec, defaultWidth: 0, defaultHeight: 0);
        applyFrameworkElementDefaults(view);
        
        // We'll use item padding to space out our items
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        
        processElementProperty(controlSpec["orientation"], setValue: { (value) in
            var orientation = self.toOrientation(value, defaultOrientation: Orientation.Horizontal);
            if (orientation == Orientation.Horizontal)
            {
                layout.scrollDirection = UICollectionViewScrollDirection.Vertical;
            }
            else
            {
                layout.scrollDirection = UICollectionViewScrollDirection.Horizontal;
            }
        });
        
        // Need support for fixed item height/width - has implications to item positioning within fixed dimension
        //
        processElementProperty(controlSpec["itemHeight"], setValue: { (value) in
            if let theValue = value
            {
                layout.itemHeight = CGFloat(self.toDeviceUnits(theValue));
            }
        });
        processElementProperty(controlSpec["itemWidth"], setValue: { (value) in
            if let theValue = value
            {
                layout.itemWidth = CGFloat(self.toDeviceUnits(theValue));
            }
        });
        
        processThicknessProperty(controlSpec["padding"], thicknessSetter: PaddingThicknessSetter(layout: layout));
        
        if let contents = controlSpec["contents"] as? JArray
        {
            createControls(controlList: contents, onCreateControl: { (childControlSpec, childControlWrapper) in
                source.controlWrappers.append(childControlWrapper);
            });
        }

        view.registerClass(WrapPanelCell.self, forCellWithReuseIdentifier: wrapPanelCellID);
        view.dataSource = source;
        
        view.layoutSubviews();
    }
}
