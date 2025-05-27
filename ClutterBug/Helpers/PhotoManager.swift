
import UIKit // For UIImage
import Foundation // For FileManager and URL operations

class PhotoManager {
    static let shared = PhotoManager() // Singleton instance
    private let fileManager = FileManager.default
    private let photosDirectoryName = "ClutterBugPhotos" // Name of the subdirectory for photos

    private init() { // Private initializer for singleton
        createPhotosDirectoryIfNeeded()
    }

    // Returns the URL for the dedicated photos directory
    private func getPhotosDirectoryURL() -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not access Documents directory.")
            return nil
        }
        return documentsDirectory.appendingPathComponent(photosDirectoryName)
    }

    // Creates the photos subdirectory if it doesn't already exist
    private func createPhotosDirectoryIfNeeded() {
        guard let photosDirectoryURL = getPhotosDirectoryURL() else { return }

        if !fileManager.fileExists(atPath: photosDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: photosDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                print("Successfully created photos directory at: \(photosDirectoryURL.path)")
            } catch {
                print("Error creating photos directory: \(error.localizedDescription)")
            }
        }
    }

    // Returns the full URL for a specific photo file given its identifier
    private func getPhotoURL(identifier: String) -> URL? {
        // Use a common extension or store it, for simplicity, let's assume PNG or derive from data.
        // For this example, we'll just use the identifier as the filename.
        // You might want to add an extension like ".png" or ".jpeg".
        return getPhotosDirectoryURL()?.appendingPathComponent(identifier + ".png") // Assuming PNG for now
    }

    // Saves image data to disk
    func saveImage(data: Data, identifier: String) {
        guard let photoURL = getPhotoURL(identifier: identifier) else {
            print("Error: Could not get photo URL for saving identifier \(identifier).")
            return
        }

        do {
            try data.write(to: photoURL)
            print("Successfully saved photo with identifier \(identifier) to \(photoURL.path)")
        } catch {
            print("Error saving photo with identifier \(identifier): \(error.localizedDescription)")
        }
    }

    // Loads an image from disk
    func loadImage(identifier: String) -> UIImage? {
        guard let photoURL = getPhotoURL(identifier: identifier) else {
            print("Error: Could not get photo URL for loading identifier \(identifier).")
            return nil
        }

        if fileManager.fileExists(atPath: photoURL.path) {
            do {
                let imageData = try Data(contentsOf: photoURL)
                return UIImage(data: imageData)
            } catch {
                print("Error loading image data for identifier \(identifier): \(error.localizedDescription)")
                return nil
            }
        } else {
            // print("Photo not found for identifier \(identifier) at path \(photoURL.path)") // Can be noisy
            return nil
        }
    }

    // Deletes an image from disk
    func deleteImage(identifier: String) {
        guard let photoURL = getPhotoURL(identifier: identifier) else {
            print("Error: Could not get photo URL for deleting identifier \(identifier).")
            return
        }

        if fileManager.fileExists(atPath: photoURL.path) {
            do {
                try fileManager.removeItem(at: photoURL)
                print("Successfully deleted photo with identifier \(identifier) from \(photoURL.path)")
            } catch {
                print("Error deleting photo with identifier \(identifier): \(error.localizedDescription)")
            }
        } else {
            print("Photo not found for deletion with identifier \(identifier), cannot delete.")
        }
    }
}



