//
//  ViewController.swift
//  word count
//
//  Created by Peter Choi on 2018. 9. 11..
//  Copyright © 2018년 RiDsoft. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate, UIPopoverPresentationControllerDelegate {
    
    private static let KEY_SAVED_DOC = "saved_doc"
    
    @IBOutlet weak var infoView: RoundedView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var spaceButton: UIButton!
    
    @IBOutlet weak var textViewBottom: NSLayoutConstraint!
    
    
    private var isEdited = false
    private var spaceType: SpaceType = .both
    private var displayOptions: [DisplayOption] = [.characters, .words]
    
    private var document: Document?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        // Navigation bar
        navigationController?.navigationBar.barTintColor = UIColor(named: "bg_primary")
        navigationController?.navigationItem.title = NSLocalizedString("app_name", comment: "app_name")
        
        textView.delegate = self
        
        initView()
        setInfoLabel()
        
    }
    
    // MARK: - View initialization
    private func initView() {
        // Constraints
        
        // TextView settings
        textView.text = NSLocalizedString("text_view_placeholder", comment: "text_view_placeholder")
        textView.textContainerInset = UIEdgeInsets(top: infoView.frame.height + 24, left: 16, bottom: 8, right: 16)
        textView.alpha = 0.35
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // InfoView settings
        infoView.showShadow()
        
        // SpaceButton settins
        if #available(iOS 14.0, *) {
            var spaceButtonActions: [UIAction] = Array()
            for t in [SpaceType.both, SpaceType.onlySpace, SpaceType.onlyEnter, SpaceType.neither] {
                let action = UIAction(title: getSpaceTypeTitle(type: t), image: nil, handler: { _ in
                    self.spaceType = t
                    self.setInfoLabel()
                })
                spaceButtonActions.append(action)
            }
            let spaceButtonMenu = UIMenu(title: NSLocalizedString("space_menu", comment: ""), options: .displayInline, children: spaceButtonActions)
            
            spaceButton.menu = spaceButtonMenu
            spaceButton.showsMenuAsPrimaryAction = true
            
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    @objc
    func keyboardWillShow(_ sender: Notification) {
        if let keyboardFrame: NSValue = sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            textViewBottom.constant = keyboardHeight
        }
    }
    
    @objc
    func keyboardWillHide(_ sender: Notification) {
        textViewBottom.constant = 0
    }
    
    // MARK: - Button click listeners
    @IBAction func onPasteButtonClick(_ sender: UIButton) {
    }
    
    @IBAction func onClearButtonClick(_ sender: Any) {
        let title = NSLocalizedString("alert_clear", comment: "alert_clear")
        let message = NSLocalizedString("alert_clear_msg", comment: "alert_clear_msg")
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let cancel = UIAlertAction(title: NSLocalizedString("cancel", comment: "cancel"), style: .cancel, handler: nil)
        let confirm = UIAlertAction(title: NSLocalizedString("clear", comment: "clear"), style: .destructive) { (action) in
            self.isEdited = false
            self.initView()
            self.setInfoLabel()
            self.view.endEditing(true)
        }
        
        alert.addAction(cancel)
        alert.addAction(confirm)
        
        setActionSheet(alert, barButton: sender as? UIBarButtonItem)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onSpaceSettingButtonClick(_ sender: Any) {
        if #available(iOS 14.0, *) {
            // No action required
        } else {
            let title = NSLocalizedString("alert_space", comment: "alert_space")
            let message = NSLocalizedString("alert_space_msg", comment: "alert_space_msg") + getSpaceTypeTitle(type: spaceType)
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            
            for t in [SpaceType.both, SpaceType.onlySpace, SpaceType.onlyEnter, SpaceType.neither] {
                let action = UIAlertAction(title: getSpaceTypeTitle(type: t), style: .default) { (action) in
                    self.spaceType = t
                    self.setInfoLabel()
                }
                alert.addAction(action)
            }
            
            let cancel = UIAlertAction(title: NSLocalizedString("cancel", comment: "cancel"), style: .cancel, handler: nil)
            alert.addAction(cancel)
            
            setActionSheet(alert, barButton: sender as? UIBarButtonItem)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func onSaveButtonClick(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: NSLocalizedString("alert_save", comment: "alert_save"), message: NSLocalizedString("alert_save_message", comment: "alert_save_message"), preferredStyle: .actionSheet)
        let confirm = UIAlertAction(title: NSLocalizedString("confirm", comment: "confirm"), style: .default) { action in
            self.saveDocument()
            self.navigationController?.popViewController(animated: true)
        }
        let cancel = UIAlertAction(title: NSLocalizedString("cancel", comment: "cancel"), style: .cancel, handler: nil)
        
        alert.addAction(confirm)
        alert.addAction(cancel)
        
        setActionSheet(alert, barButton: sender)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - BottomSheet configurations
    private func addBottomSheet() {
        let bottomSheetVC = storyboard?.instantiateViewController(withIdentifier: "optionsViewController") as! OptionsViewController
        
        let height = view.frame.height
        let width = view.frame.width
        bottomSheetVC.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: width, height: height)
        
        bottomSheetVC.modalPresentationStyle = .overFullScreen
        
        present(bottomSheetVC, animated: true, completion: nil)
    }
    
    // MARK: - Document saving
    private func saveDocument() {
        if let document = document {
            DataManager().saveDocument(document: document)
            
        } else {
            document = Document(content: textView.text)
            DataManager().saveDocument(document: document!)
        }
    }
    
    // MARK: - UITextView configurations
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if !isEdited {
            isEdited = true
            textView.text = nil
            textView.alpha = 0.6
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            isEdited = false
            textView.alpha = 0.35
            initView()
            setInfoLabel()
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        setInfoLabel()
    }
    
    // MARK: - InfoView configurations
    private func setInfoLabel() {
        let words = NSLocalizedString("words", comment: "words")
        let chars = NSLocalizedString("chars", comment: "chars")
        
        if isEdited {
            let wordsCount: Int = countWords()
            let charsCount: Int = countLetters()
            
            let info = "\(words): \(wordsCount), \(chars): \(charsCount)"
            infoLabel.text = info
        } else {
            infoLabel.text = NSLocalizedString("not_writed", comment: "not_writed")
        }
        
    }
    
    private func countLetters() -> Int {
        var count = textView.text.count
        switch spaceType {
        case .both:
            break
        case .onlySpace:
            guard let text = textView.text else {
                break
            }
            count = text.replace(target: "\n", withString: "").count
            break
        case .onlyEnter:
            guard let text = textView.text else {
                break
            }
            count = text.replace(target: " ", withString: "").count
            break
        case .neither:
            guard let text = textView.text else {
                break
            }
            let spaceRemoved = text.replace(target: " ", withString: "")
            count = spaceRemoved.replace(target: "\n", withString: "").count
            break
        }
        return count
    }
    
    private func countWords() -> Int {
        let string = textView.text
        let words = string?.split(maxSplits: Int.max, omittingEmptySubsequences: true, whereSeparator: {
            $0 == " " || $0 == "\n"
        })
        return words?.count ?? 0
    }
    
    private func getSpaceTypeTitle(type: SpaceType) -> String {
        switch type {
        case .both: return NSLocalizedString("alert_space_include", comment: "alert_space_include")
        case .neither: return NSLocalizedString("alert_space_exclude", comment: "alert_space_exclude")
        case .onlySpace: return NSLocalizedString("alert_space_include_space", comment: "alert_space_include_space")
        case .onlyEnter: return NSLocalizedString("alert_space_include_enter", comment: "alert_space_include_enter")
        }
    }
    
    private func setActionSheet(_ alert: UIAlertController, barButton: UIBarButtonItem?) {
        if let barButton = barButton {
            if let popoverController = alert.popoverPresentationController {
                popoverController.barButtonItem = barButton
            }
        } else {
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
        }
    }

}

class FloatingMoreButton : UIButton {
    public static let PADDING_TOP: CGFloat = 0
    public static let PADDING_BOTTOM: CGFloat = 0
    public static let PADDING_LEFT: CGFloat = 10.0
    public static let PADDING_RIGHT: CGFloat = 10.0
    
    override func draw(_ rect: CGRect) {
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.cornerRadius = frame.size.height / 2
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowOpacity = 0.3
        self.layer.masksToBounds = false
        
        let insets = UIEdgeInsets(top: FloatingMoreButton.PADDING_TOP, left: FloatingMoreButton.PADDING_LEFT, bottom: FloatingMoreButton.PADDING_BOTTOM, right: FloatingMoreButton.PADDING_RIGHT)
        
        self.imageEdgeInsets = insets
    }
}

extension String {
    func replace(target: String, withString: String) -> String {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
    func subString(to: Int) -> String {
        if to >= self.count || self.count == 0 {
            return self
        }
        let end = index(startIndex, offsetBy: to)
        return String(self[startIndex..<end]) + "......"
    }
}
