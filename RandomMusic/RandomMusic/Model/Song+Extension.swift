import UIKit

extension Song {
    var thumbnailImage: UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsDirectory.appendingPathComponent(self.thumbnail ?? "")
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }

        return nil
    }

    func toModel() -> SongModel {
        SongModel(title: self.title!, album: self.album!, artist: self.artist!, genre: self.genre!, id: Int(exactly: self.id)!, streamUrl: self.streamUrl!, thumbnailData: Data())
    }
}
