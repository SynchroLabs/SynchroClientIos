//
//  iOSTextBoxWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSTextBoxWrapper");


class TextViewFontSetter : iOSFontSetter
{
    var _controlWrapper: iOSTextBoxWrapper;
    var _textView: UITextView;
    
    internal init(controlWrapper: iOSTextBoxWrapper, textView: UITextView)
    {
        _controlWrapper = controlWrapper;
        _textView = textView;
        super.init(font: textView.font!);
    }
    
    internal override func setFont(_ font: UIFont)
    {
        _textView.font = font;
        _controlWrapper.updateTextViewHeight(self._textView);
    }
}

class TextFieldFontSetter : iOSFontSetter
{
    var _controlWrapper: iOSTextBoxWrapper;
    var _textField: UITextField;
    
    internal init(controlWrapper: iOSTextBoxWrapper, textField: UITextField)
    {
        _controlWrapper = controlWrapper;
        _textField = textField;
        super.init(font: textField.font!);
    }
    
    internal override func setFont(_ font: UIFont)
    {
        _textField.font = font;
        
        // iOS always returns a height of 30 units when the borderStyle is RoundedRect.  If you
        // want to compute the height required by a custom font, you have to change the borderStyle
        // to any other value, compute the height, and change the borderStyle back.
        //
        _textField.borderStyle = UITextBorderStyle.none;
        _controlWrapper.updateTextFieldHeight(self._textField);
        _textField.borderStyle = UITextBorderStyle.roundedRect;
    }
}

// This class is necessary to support "inset" (required to position placeholder appropriately
// in TextView)
//
class TextField: UITextField
{
    var inset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);
    
    override func textRect(forBounds bounds: CGRect) -> CGRect
    {
        return UIEdgeInsetsInsetRect(bounds, inset);
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect
    {
        return UIEdgeInsetsInsetRect(bounds, inset);
    }
}

// This class implements a UITextView that has a UITextField behind it, where the UITextField
// provides the border and the placeholder text functionality (so that the TextView looks and 
// works like a UITextField).
//
class TextView : UITextView, UITextViewDelegate
{
    var textField = TextField();
    
    required init?(coder: NSCoder)
    {
        fatalError("This class doesn't support NSCoding.")
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?)
    {
        super.init(frame: frame, textContainer: textContainer);
        
        self.delegate = self;
        
        // Create a background TextField with clear (invisible) text and disabled
        self.textField.borderStyle = UITextBorderStyle.roundedRect;
        self.textField.textColor = UIColor.clear;
        self.textField.isUserInteractionEnabled = false;

        // Align the background TextView to where text appears in the TextField, so that any
        // placeholder will be in the correct position.
        self.textField.contentVerticalAlignment = UIControlContentVerticalAlignment.top;
        self.textField.inset = UIEdgeInsets(
            top: self.textContainerInset.top,
            left: self.textContainerInset.left + self.textContainer.lineFragmentPadding,
            bottom: self.textContainerInset.bottom,
            right: self.textContainerInset.right
        );
        
        // The background TextField should use the same font (for the placeholder)
        self.textField.font = self.font;
        
        self.addSubview(textField);
        self.sendSubview(toBack: textField);
    }
    
    convenience init()
    {
        self.init(frame: CGRect.zero, textContainer: nil)
    }
    
    override internal var text : String?
    {
        didSet
        {
            self.textField.text = self.text;
        }
    }
    
    override var font: UIFont?
    {
        didSet
        {
            // Keep the font of the TextView and background textField in sync
            self.textField.font = self.font;

            // When the font changes size on a "wrap content" TextField, it does not update the placeholder
            // position unless the text is reset (the placeholder text changes size on it's existing baseline,
            // which is pretty much 100% incorrect in any circumstance).  This fix doesn't seem very "sturdy", 
            // but it appears to work.
            //
            self.textField.text = self.textField.text;
        }
    }
    
    var placeholder: String? = nil
    {
        didSet
        {
            self.textField.placeholder = self.placeholder;
        }
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        // Do not scroll the background textView
        self.textField.frame = CGRect(x: 0, y: self.contentOffset.y, width: self.frame.width, height: self.frame.height);
    }
    
    // UITextViewDelegate - Note: If you replace delegate, your delegate must call this
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        // Do not scroll the background textView
        self.textField.frame = CGRect(x: 0, y: self.contentOffset.y, width: self.frame.width, height: self.frame.height);
    }
    
    // UITextViewDelegate - Note: If you replace delegate, your delegate must call this
    func textViewDidChange(_ textView: UITextView)
    {
        // Updating the text in the background textView will cause the placeholder to appear/disappear
        // (including any animations of that behavior - since the textView is doing this itself).
        self.textField.text = self.text;
    }
}

open class iOSTextBoxWrapper : iOSControlWrapper, UITextViewDelegate
{
    var _updateOnChange = false;
    var _lines : Double = 1;
    
    // !!! Font color support?  Forground?
    
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating textbox element");

        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        if ((controlSpec["multiline"] != nil) && (controlSpec["multiline"]?.asBool() == true))
        {
            // Multi-line
            //
            logger.debug("Multi-line");
            
            let _textView = TextView();
            self._control = _textView;
            
            _textView.delegate = self;
            _textView.isSelectable = true;
            
            processElementDimensions(controlSpec, defaultWidth: 100); // Default width of 100
            
            applyFrameworkElementDefaults(_textView);
            
            _textView.text = " "; // You have to set text into UITextView in order for it to have a font

            // Setting the font property to itself triggers the setter logic to sync the placeholder font.  We have to do this
            // because there may not be a font attribute to set an explicit font and thus sync them up.
            _textView.font = _textView.font ?? nil;

            processFontAttribute(controlSpec, fontSetter: TextViewFontSetter(controlWrapper: self, textView: _textView));
            _textView.text = "";
            
            processElementProperty(controlSpec, attributeName: "lines", setValue: { (value) in self._lines = self.toDouble(value); self.updateTextViewHeight(_textView); });
            
            if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "value")
            {
                if (!self.processElementBoundValue("value", attributeValue: bindingSpec["value"], getValue: { () in return JValue(_textView.text!) }, setValue: { (value) in _textView.text = self.toString(value) }))
                {
                    processElementProperty(controlSpec, attributeName: "value", setValue: { (value) in _textView.text = self.toString(value) });
                    _textView.sizeToFit();
                }
                
                if (bindingSpec["sync"]?.asString() == "change")
                {
                    _updateOnChange = true;
                }
            }
            
            processElementProperty(controlSpec, attributeName: "placeholder", setValue: { (value) in _textView.placeholder = self.toString(value) });
        }
        else
        {
            // Single line
            //
            logger.debug("Single line");

            let _textField = UITextField();
            self._control = _textField;
            
            if (controlSpec["control"]?.asString() == "password")
            {
                _textField.isSecureTextEntry = true;
            }
            
            _textField.borderStyle = UITextBorderStyle.roundedRect;
            
            processElementDimensions(controlSpec, defaultWidth: 100); // Default width of 100
            
            applyFrameworkElementDefaults(_textField);
            
            processFontAttribute(controlSpec, fontSetter: TextFieldFontSetter(controlWrapper: self, textField: _textField));

            if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "value")
            {
                if (!self.processElementBoundValue("value", attributeValue: bindingSpec["value"], getValue: { () in return JValue(_textField.text!) }, setValue: { (value) in _textField.text = self.toString(value) }))
                {
                    processElementProperty(controlSpec, attributeName: "value", setValue: { (value) in _textField.text = self.toString(value) });
                    _textField.sizeToFit();
                }
                
                if (bindingSpec["sync"]?.asString() == "change")
                {
                    _updateOnChange = true;
                }
            }
            
            processElementProperty(controlSpec, attributeName: "placeholder", setValue: { (value) in _textField.placeholder = self.toString(value) });
            
            _textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged);
        }
    }
    
    func updateTextViewHeight(_ textView: UITextView)
    {
        if (self.frameProperties.heightSpec == SizeSpec.wrapContent)
        {
            if let font = textView.font
            {
                textView.bounds.height = (font.lineHeight * CGFloat(self._lines)) + textView.textContainerInset.top + textView.textContainerInset.bottom;
            }
        }
    }

    func updateTextFieldHeight(_ textField: UITextField)
    {
        if (self.frameProperties.heightSpec == SizeSpec.wrapContent)
        {
            let sizeThatFits = textField.sizeThatFits(CGSize(width: textField.bounds.width, height: CGFloat.greatestFiniteMagnitude));
            textField.bounds.height = sizeThatFits.height;
            logger.info("Set size to height: \(sizeThatFits.height)");
            logger.info("Intrinsic content size: \(textField.intrinsicContentSize)")
        }
    }

    open func editingChanged(_ sender: AnyObject)
    {
        // This is basically the "onChange" event...
        //
        // Edit controls have a bad habit of posting a text changed event, and there are cases where
        // this event is generated based on programmatic setting of text and comes in asynchronously
        // after that programmatic action, making it difficult to distinguish actual user changes.
        // This shortcut will help a lot of the time, but there are still cases where this will be
        // signalled incorrectly (such as in the case where a control with focus is the target of
        // an update from the server), so we'll do some downstream delta checking as well, but this
        // check will cut down most of the chatter.
        //
        if (_control!.isFirstResponder)
        {
            updateValueBindingForAttribute("value");
            if (_updateOnChange)
            {
                self.stateManager.sendUpdateRequestAsync();
            }
        }
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        if let theTextView = scrollView as? TextView
        {
            theTextView.scrollViewDidScroll(scrollView);
        }
    }
    
    open func textViewDidChange(_ textView: UITextView)
    {
        if let theTextView = textView as? TextView
        {
            theTextView.textViewDidChange(textView);
        }

        // Same logic as editingChanged() above, but for UITextView (via delegate)
        //
        if (_control!.isFirstResponder)
        {
            updateValueBindingForAttribute("value");
            if (_updateOnChange)
            {
                self.stateManager.sendUpdateRequestAsync();
            }
        }
    }
}
