//
//  ViewController.swift
//  Teki
//
//  Created by Gilles Sagot on 28/01/2021.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var composition: CompoView!
    @IBOutlet weak var arrow: UIImageView!
    @IBOutlet weak var layoutButtonLeft: UIButton!
    @IBOutlet weak var layoutButtonMiddle: UIButton!
    @IBOutlet weak var layoutButtonRight: UIButton!
    @IBOutlet weak var selectedImage: UIImageView!
    @IBOutlet weak var selectedImageConstraintToUpdateInLanscape: NSLayoutConstraint!
    @IBOutlet weak var selectedImageConstraintToUpdateInPortrait: NSLayoutConstraint!
    
    var isLandscape:Bool = false
     
    var gestureOnlyLeftAndUp:Bool = false
    
    var imagePicker = UIImagePickerController()

    
    // MARK: - PREPARE ALL SUBVIEWS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // On load, the device orientation can be .Unknown or .FaceUp ... We need to find something else to hang on. This is a way to fix this
        let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        if orientation == .portrait {
            isLandscape = false
        } else if orientation == .landscapeLeft || orientation == .landscapeRight{
            isLandscape = true
        }
        changeArrowImageIfLandscape()
        // Layout main view and all subviews
        composition.layoutImages()
        composition.layoutButtons()
        
        // Choose the style to start with
        composition.style = .bigbottom

        // Add actions to buttons in the controller
        addAction()

    }
    
    // MARK: - UPDATE WITH DEVICE ORIENTATION
    
    override func viewDidAppear(_ animated: Bool) {
      // popup()
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Orientation
        findOrientation()
        changeArrowImageIfLandscape()
    }
    
    // Find orientation with UIDevice
    func findOrientation(){
        if UIDevice.current.orientation.isLandscape {
            isLandscape = true
        }
        else{
            isLandscape = false
        }
    }
    
    func changeArrowImageIfLandscape(){
        if isLandscape {
            arrow.image = UIImage(named: "Arrow Left")
        }else{
            arrow.image = UIImage(named: "Arrow Up")
        }
        
    }
    
    // MARK: - ADD ACTION TO BUTTONS IN CODE
    
    func addAction(){
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragImageLayout(_:)))
        composition.addGestureRecognizer(panGestureRecognizer)
        for i in 0..<composition.buttons.count{
        composition.buttons[i].addTarget(self, action:#selector(compositionButtonClicked), for: .touchUpInside)
        }
    }
    
    // MARK: - POPUP
    func popup () {
        
        let ac = UIAlertController(title: "Instagrid", message: "Setting up your creation first.\n Then you'll be able to share it.", preferredStyle: .alert)
    
        ac.view.tintColor = .blue
        let test = UIAlertAction(title: "Create", style: .default, handler: nil)
        ac.addAction(test)
        present(ac, animated: true)
        
    }

    
    // MARK: - ADD IMAGE IN COMPOSITION
    
    @objc func compositionButtonClicked(sender:UIButton) {
        pickImage()
        composition.index = sender.tag
    }
    
    // Open Images folder to choose an image
    func pickImage ()
    {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
                    imagePicker.sourceType = .savedPhotosAlbum
                    imagePicker.allowsEditing = false
                    imagePicker.delegate = self
                    self.present(imagePicker, animated: false, completion: nil)
           
        }
    }
    
    // Add selected image in composition in the right place
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            composition.currentImage = pickedImage
        }
        self.dismiss(animated: true, completion: nil)
        composition.images[composition.index].image = composition.currentImage
        composition.buttons[composition.index].setBackgroundImage(UIGraphicsGetImageFromCurrentImageContext(), for: .normal)
    }
    
    // MARK: - SHARE IMAGE
    
    // check if user setting up his creation and put all images in slots
    func checkCompoIsReady() -> Bool{
        var tests = composition.images
        var result:Bool=true

        switch composition.style {
        case .bigbottom:
            tests.remove(at: 3)
        case .bigtop:
            tests.remove(at: 1)
        default:
            break
        }

        for i in 0..<tests.count where __CGSizeEqualToSize(tests[i].image!.size , CGSize(width: 0,height: 0)){
                result = false
                break
        }

       return result
            
    }
    
    // User Drag inside composition...
    @objc func dragImageLayout(_ sender: UIPanGestureRecognizer) {
        if (sender.state == .began || sender.state == .changed) {
            moveCompositionViewWith(gesture: sender)
        }
        else if (sender.state == .ended || sender.state == .cancelled) && gestureOnlyLeftAndUp == true{
            shareCompositionView()
        }
    }
    
    // ...Composition moves for began and changed states...
    private func moveCompositionViewWith(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: composition)
        if isLandscape == true && translation.x < -0 {
            composition.transform = CGAffineTransform(translationX: translation.x, y: 0)
            gestureOnlyLeftAndUp = true
        }
        else if isLandscape == false && translation.y < -0 {
            composition.transform = CGAffineTransform(translationX: 0, y: translation.y)
            gestureOnlyLeftAndUp = true
        }
    }
    
    // ...Then composition is share with cancelled or ended states
    private func shareCompositionView() {
        if checkCompoIsReady() {
            let item = [composition.imageToShare]
            let ac = UIActivityViewController(activityItems: item as [Any], applicationActivities: nil)
            self.present(ac, animated: true)
        }
        else
        {
            popup()
        }

        composition.transform = .identity
        gestureOnlyLeftAndUp = false
    }
    
    
    // Update style layout with user choice
    @IBAction func setStyle(_ sender: UIButton) {
        var selectedImageConstraintToUpdate = CGFloat()
        switch sender.tag {
        case 101:
            composition.style = .bigbottom
            selectedImage.frame = layoutButtonLeft.frame
            selectedImageConstraintToUpdate = 30
        case 102:
            composition.style = .bigtop
            selectedImage.frame = layoutButtonLeft.frame
            selectedImageConstraintToUpdate = -80
        default:
            composition.style = .standard
            selectedImage.frame = layoutButtonRight.frame
            selectedImageConstraintToUpdate = -190
            
        }
        if isLandscape {
            selectedImageConstraintToUpdateInLanscape.constant = selectedImageConstraintToUpdate
        }else{
            selectedImageConstraintToUpdateInPortrait.constant = selectedImageConstraintToUpdate
        }
    }
    
}

