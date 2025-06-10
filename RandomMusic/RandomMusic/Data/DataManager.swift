import Foundation
import CoreData

final class DataManager {
    static let shared = DataManager()

    let mainContext: NSManagedObjectContext
    let persistentContainer: NSPersistentContainer
    let fetchedResults: NSFetchedResultsController<Song>

    /// 코어 데이터 초기화 및 데이터를 가져옵니다.
    private init() {
        let container = NSPersistentContainer(name: "RandomMusic")

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        persistentContainer = container
        mainContext = container.viewContext

        let request = Song.fetchRequest()
        let sortedByDate = NSSortDescriptor(keyPath: \Song.insertDate, ascending: false)
        request.sortDescriptors = [sortedByDate]

        fetchedResults = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: mainContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        do {
            try fetchedResults.performFetch()
        } catch {
            print(error)
        }
    }
    
    /// 음악 데이터를 영구적으로 저장합니다.
    /// - Parameter song: 저장할 음악 데이터를 받습니다.
    func insertSongData(from song: SongModel) {
        let newSong = Song(context: mainContext)
        newSong.title = song.title
        newSong.album = song.album
        newSong.artist = song.artist
        newSong.genre = song.genre
        newSong.id = Int64(song.id)
        newSong.streamUrl = song.streamUrl
        newSong.insertDate = .now

        let thumbnailFileName = String(newSong.id) + ".jpg"
        newSong.thumbnail = thumbnailFileName

        insertImageFile(fileName: thumbnailFileName, data: song.thumbnailData)
        saveContext()
    }

    // TODO: 오버로딩이 필요할 수도 있음. (다른 파라미터를 받는 Delete 메소드)
    /// 음악 데이터를 영구적으로 삭제합니다.
    /// - Parameter indexPath: 삭제할 음악 데이터의 IndexPath를 받습니다.
    func deleteSongData(at indexPath: IndexPath) {
        let deletedSong = fetchedResults.object(at: indexPath)

        deleteImageFile(fileName: deletedSong.thumbnail)
        mainContext.delete(deletedSong)
        saveContext()
    }

    // TODO: 알고리즘에 따라 수치는 변경될 수 있습니다.
    /// 장르별 추천 수치를 조정합니다.
    /// - Parameters:
    ///   - genre: 음악 장르를 받습니다. (예: "rock", "ballad")
    ///   - delta: 추천 시 양수, 비추천 시 음수 값을 받습니다.
    func adjustGenreScore(for genre: String, by delta: Int) {
        var genreCounts = UserDefaults.standard.dictionary(forKey: "Genre") as? [String: Int] ?? [:]

        let current = genreCounts[genre] ?? 0
        let updated = max(current + delta, 1)
        genreCounts[genre] = updated

        UserDefaults.standard.set(genreCounts, forKey: "Genre")
    }

    /// 장르별 추천 수치를 모두 반환합니다.
    /// - Returns: 장르별 추천 수치를 배열로 반환합니다.
    func fetchAllGenre() -> [(genre: String, count: Int)] {
        if let genreCounts = UserDefaults.standard.dictionary(forKey: "Genre") as? [String: Int] {
			return Array(genreCounts).sorted { $0.value > $1.value }.map { (genre: $0.key, count: $0.value) }
        }

        return []
    }

    func fetchSongsOrderedByInsertedDate() -> [SongModel] {
        let request: NSFetchRequest<Song> = Song.fetchRequest()

        // insertedDate를 오름차순 정렬
        let sortDescriptor = NSSortDescriptor(key: "insertDate", ascending: true)
        request.sortDescriptors = [sortDescriptor]

        do {
            let songs = try mainContext.fetch(request)
            return songs.map { $0.toModel() }
        } catch {
            print("Failed to fetch songs: \(error)")
            return []
        }
    }

    /// Context에서 변경된 데이터를 영구적으로 저장합니다.
    func saveContext() {
        let context = persistentContainer.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

private extension DataManager {
    /// 디렉토리에 이미지 데이터를 저장합니다.
    /// - Parameters:
    ///   - name: 이미지 파일의 이름을 받습니다.
    ///   - data: 저장될 바이너리 데이터를 받습니다.
    func insertImageFile(fileName: String, data: Data?) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pathUrl = documentDirectory.appending(path: fileName)

        do {
            try data?.write(to: pathUrl)
        } catch {
            print(error.localizedDescription)
        }
    }

    /// 디렉토리에 존재하는 이미지를 삭제합니다.
    /// - Parameter fileName: 디렉토리에 저장된 파일 이름을 받습니다.
    func deleteImageFile(fileName: String?) {
        if let fileName {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let pathUrl = documentDirectory.appending(path: fileName)

            do {
                try FileManager.default.removeItem(at: pathUrl)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
