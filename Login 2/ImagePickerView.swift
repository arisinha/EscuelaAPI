import SwiftUI
import PhotosUI

struct ImagePickerView: UIViewControllerRepresentable {
    let onImageSelected: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let actionSheet = UIAlertController(title: "Seleccionar imagen", message: nil, preferredStyle: .actionSheet)
        
        // Opción de cámara
        let cameraAction = UIAlertAction(title: "Cámara", style: .default) { _ in
            let camera = CameraViewController { image in
                onImageSelected(image)
            }
            context.coordinator.presentCamera(camera)
        }
        
        // Opción de galería
        let galleryAction = UIAlertAction(title: "Galería", style: .default) { _ in
            let gallery = PhotoLibraryViewController { image in
                onImageSelected(image)
            }
            context.coordinator.presentGallery(gallery)
        }
        
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel) { _ in
            onImageSelected(nil)
        }
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(galleryAction)
        actionSheet.addAction(cancelAction)
        
        return actionSheet
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func presentCamera(_ camera: CameraViewController) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(camera, animated: true)
            }
        }
        
        func presentGallery(_ gallery: PhotoLibraryViewController) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(gallery, animated: true)
            }
        }
    }
}

// Controlador para la cámara
class CameraViewController: UIImagePickerController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let onImageSelected: (UIImage?) -> Void
    
    init(onImageSelected: @escaping (UIImage?) -> Void) {
        self.onImageSelected = onImageSelected
        super.init(nibName: nil, bundle: nil)
        
        self.sourceType = .camera
        self.delegate = self
        self.allowsEditing = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        onImageSelected(image)
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        onImageSelected(nil)
        dismiss(animated: true)
    }
}

// Controlador para la galería de fotos
class PhotoLibraryViewController: UIImagePickerController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let onImageSelected: (UIImage?) -> Void
    
    init(onImageSelected: @escaping (UIImage?) -> Void) {
        self.onImageSelected = onImageSelected
        super.init(nibName: nil, bundle: nil)
        
        self.sourceType = .photoLibrary
        self.delegate = self
        self.allowsEditing = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        onImageSelected(image)
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        onImageSelected(nil)
        dismiss(animated: true)
    }
}