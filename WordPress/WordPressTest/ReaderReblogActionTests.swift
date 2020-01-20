@testable import WordPress
import CoreData
import XCTest


class MockReblogPresenter: ReaderReblogPresenter {
    var presentReblogExpectation: XCTestExpectation?

    override func presentReblog(blogService: BlogService, readerPost: ReaderPost, origin: UIViewController) {
        presentReblogExpectation?.fulfill()
    }
}

class MockBlogService: BlogService {
    var blogsForAllAccountsExpectation: XCTestExpectation?
    var lastUsedOrFirstBlogExpectation: XCTestExpectation?

    var blogCount = 1

    override func blogCountForAllAccounts() -> Int {
        return blogCount
    }

    override func blogsForAllAccounts() -> [Blog] {
        blogsForAllAccountsExpectation?.fulfill()
        return [Blog(context: self.managedObjectContext), Blog(context: self.managedObjectContext)]
    }
    override func lastUsedOrFirstBlog() -> Blog? {
        lastUsedOrFirstBlogExpectation?.fulfill()
        return Blog(context: self.managedObjectContext)
    }
}

class MockPostService: PostService {
    var draftPostExpectation: XCTestExpectation?

    override func createDraftPost(for blog: Blog) -> Post {
        draftPostExpectation?.fulfill()
        return Post(context: self.managedObjectContext)
    }
}

class MockCoreData {
    /// creates an in-memory store
    class func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext? {

        do {
            let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel!)
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
            let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
            return managedObjectContext
        } catch {
            print("Adding in-memory persistent store failed")
            return nil
        }
    }
}

class ReblogTestCase: XCTestCase {
    var context: NSManagedObjectContext?
    var readerPost: ReaderPost?
    var blogService: MockBlogService?
    var postService: MockPostService?

    override func setUp() {
        context = MockCoreData.setUpInMemoryManagedObjectContext()
        readerPost = ReaderPost(context: self.context!)
        blogService = MockBlogService(managedObjectContext: self.context!)
        postService = MockPostService(managedObjectContext: self.context!)
    }

    override func tearDown() {
        context = nil
        readerPost = nil
        blogService = nil
        postService = nil
    }
}

class ReaderReblogActionTests: ReblogTestCase {

    func testExecuteAction() {
        // Given
        let presenter = MockReblogPresenter(postService: postService!)
        presenter.presentReblogExpectation = expectation(description: "presentBlog was called")
        let action = ReaderReblogAction(blogService: blogService!, presenter: presenter)
        let controller = UIViewController()
        // When
        action.execute(readerPost: readerPost!, origin: controller, reblogSource: .list)
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
}

class ReblogPresenterTests: ReblogTestCase {

    func testPresentEditorForOneSite() {
        // Given
        postService!.draftPostExpectation = expectation(description: "createDraftPost was called")
        blogService!.blogsForAllAccountsExpectation = expectation(description: "blogsForAllAccounts was called")
        let presenter = ReaderReblogPresenter(postService: postService!)
        // When
        presenter.presentReblog(blogService: blogService!, readerPost: readerPost!, origin: UIViewController())
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testPresentEditorForMultipleSites() {
        // Given
        blogService!.lastUsedOrFirstBlogExpectation = expectation(description: "lastUsedOrFirstBlog was called")
        blogService!.blogCount = 2
        let presenter = ReaderReblogPresenter(postService: postService!)
        // When
        presenter.presentReblog(blogService: blogService!, readerPost: readerPost!, origin: UIViewController())
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
}

class ReblogFormatterTests: XCTestCase {

    func testWordPressQuote() {
        // Given
        let quote = "Quote"
        // When
        let wpQuote = ReaderReblogFormatter.gutenbergQuote(text: quote)
        // Then
        XCTAssertEqual("<!-- wp:quote -->\n<blockquote class=\"wp-block-quote\"><p>Quote</p></blockquote>\n<!-- /wp:quote -->", wpQuote)
    }

    func testHyperLink() {
        // Given
        let url = "https://wordpress.com"
        let text = "WordPress.com"
        // When
        let wpLink = ReaderReblogFormatter.hyperLink(url: url, text: text)
        // Then
        XCTAssertEqual("<a href=\"https://wordpress.com\">WordPress.com</a>", wpLink)
    }

    func testImage() {
        // Given
        let image = "image.jpg"
        // When
        let wpImage = ReaderReblogFormatter.gutenbergImage(image: image)
        // Then
        XCTAssertEqual("<!-- wp:paragraph -->\n<p><img src=\"image.jpg\"></p>\n<!-- /wp:paragraph -->", wpImage)
    }
}