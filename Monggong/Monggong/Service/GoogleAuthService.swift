import Foundation
import RxSwift
import RxCocoa
import RxRelay
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
protocol GoogleAuthServiceProtocol {
//    func login() -> User
    func login() -> Observable<User>
    func logout()
}
/// google Auth
class GoogleAuthService: GoogleAuthServiceProtocol {
    var disposeBag: DisposeBag = DisposeBag()
    func login() -> Observable<User>{
        
        return Observable.create { observer in
            
            if let topVC = UIApplication.shared.topViewController(){
                
                GIDSignIn.sharedInstance.signIn(withPresenting: topVC) { [unowned self] result, error in
                    if let error = error {
                        print("ERR")
                        observer.onError(error)
                        return
                    }
                    
                    guard let user = result?.user,
                          let idToken = user.idToken?.tokenString else {
                        observer.onCompleted()
                        return }
                    
//                    let googleClientId = FirebaseApp.app()?.options.clientID ?? ""
//                    let signInConfig = GIDConfiguration.init(clientID: googleClientId)
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                                   accessToken: user.accessToken.tokenString)
                    //  signIn 메서드에 전달한 후 반환되는 Google 인증 토큰으로부터 Firebase 인증 사용자 인증 정보를 만듭니다.
                    Auth.auth().signIn(with: credential) { result, error in
                        print("로그인 실패:  \(error.debugDescription)")
                        print("로그인 성공 유저:  \(String(describing: result?.user.uid))")
                        /// id
                        let userID = result?.user.uid ?? ""
                        /// name
                        let name = result?.user.displayName ?? "달성"
                        /// profileImage
                        let urlString = result?.user.photoURL?.absoluteString ?? "https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?20150327203541"
                        
                        let userIfo: User = User(id: userID, name: name, profileURL: urlString, isLogined: true)
                        
                        UserInfo.shared.updateCurrentUser(userIfo)
                        
                        observer.on(.next(userIfo))
                        observer.on(.completed)
                        
                    } // 인증 정보
                }// GIDSignIn
            }// if let
            
            
            return Disposables.create()
        }

    } // login
    
    /// google auth logout
    func logout(){
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
} // class
