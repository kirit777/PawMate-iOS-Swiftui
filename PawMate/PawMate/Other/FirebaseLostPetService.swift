//
//  FirebaseLostPetService.swift
//  PawMate
//
//  Created by Kirit on 28/05/26.
//


import Foundation
import FirebaseDatabase

final class FirebaseLostPetService {
    static let shared = FirebaseLostPetService()
    
    private let database = Database.database().reference()
    private let lostPetsPath = "lost_pet_alerts"
    
    private init() { }
    
    func saveLostPetAlert(_ alert: LostPetAlert, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = database.child(lostPetsPath).child(alert.id.uuidString)
        
        let data: [String: Any] = [
            "id": alert.id.uuidString,
            "petName": alert.petName,
            "petType": alert.petType,
            "lastSeenLocation": alert.lastSeenLocation,
            "description": alert.description,
            "contactNumber": alert.contactNumber,
            "dateText": alert.dateText,
            "status": alert.status,
            "latitude": alert.latitude,
            "longitude": alert.longitude,
            "imageBase64": alert.imageBase64 ?? ""
        ]
        
        ref.setValue(data) { error, _ in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func observeLostPetAlerts(completion: @escaping ([LostPetAlert]) -> Void) {
        database.child(lostPetsPath).observe(.value) { snapshot in
            var alerts: [LostPetAlert] = []
            
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let dict = snap.value as? [String: Any],
                      let idString = dict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let petName = dict["petName"] as? String,
                      let petType = dict["petType"] as? String,
                      let lastSeenLocation = dict["lastSeenLocation"] as? String,
                      let description = dict["description"] as? String,
                      let contactNumber = dict["contactNumber"] as? String,
                      let dateText = dict["dateText"] as? String,
                      let status = dict["status"] as? String,
                      let latitude = dict["latitude"] as? Double,
                      let longitude = dict["longitude"] as? Double else {
                    continue
                }
                
                let imageBase64 = dict["imageBase64"] as? String
                
                alerts.append(
                    LostPetAlert(
                        id: id,
                        petName: petName,
                        petType: petType,
                        lastSeenLocation: lastSeenLocation,
                        description: description,
                        contactNumber: contactNumber,
                        dateText: dateText,
                        status: status,
                        latitude: latitude,
                        longitude: longitude,
                        imageBase64: imageBase64?.isEmpty == true ? nil : imageBase64
                    )
                )
            }
            
            completion(alerts.filter { $0.status == "ACTIVE" })
        }
    }
}