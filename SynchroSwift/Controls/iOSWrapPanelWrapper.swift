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

open class WrapPanelCell : UICollectionViewCell
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

    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func updateView(_ controlWrapper: iOSControlWrapper)
    {
        if (self.contentView.subviews.count > 0)
        {
            contentView.subviews[0].removeFromSuperview();
        }
        contentView.addSubview(controlWrapper.control!);
    }
}

open class WrapPanelCollectionViewSource : NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    var controlWrappers = [iOSControlWrapper]();

    var _itemHeight: CGFloat = 0;
    open var itemHeight: CGFloat { get { return _itemHeight; } set(value) { _itemHeight = value; } }
    
    var _itemWidth: CGFloat = 0;
    open var itemWidth: CGFloat { get { return _itemWidth; } set(value) { _itemWidth = value; } }

    public override init()
    {
        super.init();
    }
    
    // UICollectionViewDataSource method
    open func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1;
    }
    
    // UICollectionViewDataSource method
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection: Int) -> Int
    {
        return controlWrappers.count;
    }
    
    // UICollectionViewDataSource method
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: wrapPanelCellID!, for: indexPath) as! WrapPanelCell;
    
        // logger.Info("Updating cell {0} with frame: {1}", indexPath.Item, cell.Frame);
    
        let controlWrapper = controlWrappers[(indexPath as NSIndexPath).row];
        cell.updateView(controlWrapper);
    
        return cell;
    }
    
    open func shouldHighlightItem(_ collectionView: UICollectionView, indexPath: IndexPath) -> Bool
    {
        return false;
    }
    
    // UICollectionViewDelegateFlowLayout
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return self.sizeForItemAtIndexPath(indexPath);
    }

    
    open func sizeForItemAtIndexPath(_ indexPath: IndexPath) -> CGSize
    {
        let controlWrapper = controlWrappers[(indexPath as NSIndexPath).row];
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
    
    open func itemAtIndexPath(_ indexPath: IndexPath) -> iOSControlWrapper
    {
        return controlWrappers[(indexPath as NSIndexPath).row];
    }
}

open class WrapPanelCollectionViewLayout : UICollectionViewFlowLayout
{
    var _source: WrapPanelCollectionViewSource;
    
    public init(source: WrapPanelCollectionViewSource )
    {
        _source = source;
        super.init();
    }

    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    open var itemHeight: CGFloat
    {
        get { return _source.itemHeight; }
        set(value)
        {
            _source.itemHeight = value;
            self.invalidateLayout();
        }
    }
    
    open var itemWidth: CGFloat
    {
        get { return _source.itemWidth; }
        set(value)
        {
            _source.itemWidth = value;
            self.invalidateLayout();
        }
    }
    
    func positionLineElements(_ lineContents: [UICollectionViewLayoutAttributes], linePosition: CGFloat, lineThickness: CGFloat)
    {
        logger.debug("Positioning line with \(lineContents.count) elements, position: \(linePosition), thickness: \(lineThickness)");
        var lineLength: CGFloat = 0;
    
        for lineMember in lineContents
        {
            let controlWrapper = _source.itemAtIndexPath(lineMember.indexPath);
            let allocatedSize = _source.sizeForItemAtIndexPath(lineMember.indexPath);
            let actualSize = controlWrapper.control!.frame.size;
            
            var x: CGFloat;
            var y: CGFloat;
            
            if (self.scrollDirection == UICollectionViewScrollDirection.vertical)
            {
                // Vertical scroll means horizontal layout...
                //
                if (controlWrapper.horizontalAlignment == HorizontalAlignment.left)
                {
                    x = lineLength + CGFloat(controlWrapper.marginLeft);
                }
                else if (controlWrapper.horizontalAlignment == HorizontalAlignment.right)
                {
                    x = lineLength + allocatedSize.width - (actualSize.width + CGFloat(controlWrapper.marginRight));
                }
                else // HorizontalAlignment.Center - default
                {
                    x = lineLength + ((allocatedSize.width - actualSize.width) / 2);
                }
                lineLength += allocatedSize.width;
        
                if (controlWrapper.verticalAlignment == VerticalAlignment.top)
                {
                    y = linePosition + CGFloat(controlWrapper.marginTop);
                }
                else if (controlWrapper.verticalAlignment == VerticalAlignment.bottom)
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
                if (controlWrapper.horizontalAlignment == HorizontalAlignment.left)
                {
                    x = linePosition + CGFloat(controlWrapper.marginLeft);
                }
                else if (controlWrapper.horizontalAlignment == HorizontalAlignment.right)
                {
                    x = linePosition + lineThickness - (actualSize.width + CGFloat(controlWrapper.marginRight));
                }
                else // HorizontalAlignment.Center - default
                {
                    x = linePosition + ((lineThickness - actualSize.width) / 2);
                }
        
                if (controlWrapper.verticalAlignment == VerticalAlignment.top)
                {
                    y = lineLength + CGFloat(controlWrapper.marginTop);
                }
                else if (controlWrapper.verticalAlignment == VerticalAlignment.bottom)
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
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? // [UICollectionViewLayoutAttributes]
    {
        logger.debug("LayoutAttributesForElementsInRect: \(rect)");
        let attributesArray = super.layoutAttributesForElements(in: rect)!;
        
        var lineContents = [UICollectionViewLayoutAttributes]();
        
        var lineLength: CGFloat = 0;
        var linePosition: CGFloat = 0;
        var lineThickness: CGFloat = 0;
        
        for attributes in attributesArray
        {
            if (attributes.representedElementKind == nil)
            {
                attributes.frame = self.layoutAttributesForItem(at: attributes.indexPath)!.frame;
                
                if (self.scrollDirection == UICollectionViewScrollDirection.vertical)
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

open class PaddingThicknessSetter : ThicknessSetter
{
    var _layout: UICollectionViewFlowLayout;
    
    public init(layout: UICollectionViewFlowLayout)
    {
        _layout = layout;
    }
    
    open func setThickness(_ thickness: Double)
    {
        var insets = _layout.sectionInset;
        insets.left = CGFloat(thickness);
        insets.top = CGFloat(thickness);
        insets.right = CGFloat(thickness);
        insets.bottom = CGFloat(thickness);
        _layout.sectionInset = insets;
    }

    open func setThicknessLeft(_ thickness: Double)
    {
        var insets = _layout.sectionInset;
        insets.left = CGFloat(thickness);
        _layout.sectionInset = insets;
    }
    
    open func setThicknessTop(_ thickness: Double)
    {
        var insets = _layout.sectionInset;
        insets.top = CGFloat(thickness);
        _layout.sectionInset = insets;
    }
    
    open func setThicknessRight(_ thickness: Double)
    {
        var insets = _layout.sectionInset;
        insets.right = CGFloat(thickness);
        _layout.sectionInset = insets;
    }
    
    open func setThicknessBottom(_ thickness: Double)
    {
        var insets = _layout.sectionInset;
        insets.bottom = CGFloat(thickness);
        _layout.sectionInset = insets;
    }
}

open class WrapPanelCollectionView : UICollectionView
{
    var _controlWrapper: iOSControlWrapper;
    
    public init(controlWrapper: iOSControlWrapper, layout: UICollectionViewLayout)
    {
        _controlWrapper = controlWrapper;
        super.init(frame: CGRect(), collectionViewLayout: layout);
        self.backgroundColor = UIColor.clear; // UICollectionView background defaults to Black
    }

    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews()
    {
        super.layoutSubviews();
        
        if let layout = self.collectionViewLayout as? WrapPanelCollectionViewLayout
        {
            // var viewSource = self.dataSource as! WrapPanelCollectionViewSource;
            
            var frameSize = self.frame.size;
            
            if (layout.scrollDirection == UICollectionViewScrollDirection.horizontal)
            {
                // Vertical wrapping (width may vary based on contents, height must be explicit)
                //
                if (_controlWrapper.frameProperties.widthSpec == SizeSpec.wrapContent)
                {
                    frameSize.width = self.contentSize.width;
                }
            }
            else
            {
                // Horizontal wrapping (height may vary based on contents, width must be explicit)
                //
                if (_controlWrapper.frameProperties.heightSpec == SizeSpec.wrapContent)
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

open class iOSWrapPanelWrapper : iOSControlWrapper
{
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating wrappanel element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let source = WrapPanelCollectionViewSource();
        let layout = WrapPanelCollectionViewLayout(source: source);
        let view = WrapPanelCollectionView(controlWrapper: self, layout: layout);
        view.delegate = source;
        
        self._control = view;
        
        processElementDimensions(controlSpec, defaultWidth: 0, defaultHeight: 0);
        applyFrameworkElementDefaults(view);
        
        // We'll use item padding to space out our items
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        
        processElementProperty(controlSpec, attributeName: "orientation", setValue: { (value) in
            let orientation = self.toOrientation(value, defaultOrientation: Orientation.horizontal);
            if (orientation == Orientation.horizontal)
            {
                layout.scrollDirection = UICollectionViewScrollDirection.vertical;
            }
            else
            {
                layout.scrollDirection = UICollectionViewScrollDirection.horizontal;
            }
        });
        
        // Need support for fixed item height/width - has implications to item positioning within fixed dimension
        //
        processElementProperty(controlSpec, attributeName: "itemHeight", setValue: { (value) in
            if let theValue = value
            {
                layout.itemHeight = CGFloat(self.toDeviceUnits(theValue));
            }
        });
        processElementProperty(controlSpec, attributeName: "itemWidth", setValue: { (value) in
            if let theValue = value
            {
                layout.itemWidth = CGFloat(self.toDeviceUnits(theValue));
            }
        });
        
        processThicknessProperty(controlSpec, attributeName: "padding", thicknessSetter: PaddingThicknessSetter(layout: layout));
        
        if let contents = controlSpec["contents"] as? JArray
        {
            createControls(controlList: contents, onCreateControl: { (childControlSpec, childControlWrapper) in
                source.controlWrappers.append(childControlWrapper);
            });
        }

        view.register(WrapPanelCell.self, forCellWithReuseIdentifier: wrapPanelCellID!);
        view.dataSource = source;
        
        view.layoutSubviews();
    }
}
