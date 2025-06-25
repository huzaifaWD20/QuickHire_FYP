// // lib/models/job_listing.dart

// class JobListing {
//   final String id;
//   final String employer;

//   final String projectName;
//   final String jobDescription;
//   final String industry;
//   final String employmentType;
//   final String title;
//   final String experienceLevel;
//   final String? backgroundPreferences;
//   final DateTime startDate;
//   final String location;
//   final String? candidateLocation;
//   final double? radius;
//   final String relocationOptions; // Keep as String for now
//   final bool isShortlisted;
//   final DateTime createdAt;

//   JobListing({
//     required this.id,
//     required this.employer,
//     required this.projectName,
//     required this.jobDescription,
//     required this.industry,
//     required this.employmentType,
//     required this.title,
//     required this.experienceLevel,
//     this.backgroundPreferences,
//     required this.startDate,
//     required this.location,
//     this.candidateLocation,
//     this.radius,
//     required this.relocationOptions, // Keep as String for now
//     required this.isShortlisted,
//     required this.createdAt,
//   });

//   factory JobListing.fromJson(Map<String, dynamic> json) {
//     return JobListing(
//       id: json['_id'] ?? json['id'] ?? '',
//       employer: json['employer'] ?? '',
//       projectName: json['projectName'] ?? '',
//       jobDescription: json['jobDescription'] ?? '',
//       industry: json['industry'] ?? '',
//       employmentType: json['employmentType'] ?? '',
//       title: json['title'] ?? '',
//       experienceLevel: json['experienceLevel'] ?? '',
//       backgroundPreferences: json['backgroundPreferences'],
//       startDate: json['startDate'] != null 
//           ? DateTime.parse(json['startDate']) 
//           : DateTime.now(),
//       location: json['location'] ?? '',
//       candidateLocation: json['candidateLocation'],
//       radius: json['radius']?.toDouble(),
//       relocationOptions: json['relocationOptions'] ?? 'No', // Keep as String
//       isShortlisted: json['isShortlisted'] ?? false,
//       createdAt: json['createdAt'] != null 
//           ? DateTime.parse(json['createdAt']) 
//           : DateTime.now(),
//     );
//   }

//   // Convert JobListing to JSON for API
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'employer': employer,
//       'projectName': projectName,
//       'jobDescription': jobDescription,
//       'industry': industry,
//       'employmentType': employmentType,
//       'title': title,
//       'experienceLevel': experienceLevel,
//       'backgroundPreferences': backgroundPreferences,
//       'startDate': startDate.toIso8601String(),
//       'location': location,
//       'candidateLocation': candidateLocation,
//       'radius': radius,
//       'relocationOptions': relocationOptions, // Keep as String
//       'isShortlisted': isShortlisted,
//       'createdAt': createdAt.toIso8601String(),
//     };
//   }
// }


// /*
// class JobListing {
//   // Typically managed by the backend via authentication
//   final String employer;

//   final String projectName;
//   final String jobDescription;
//   final String industry;
//   final String employmentType;
//   final String title;
//   final String experienceLevel;
//   final String? backgroundPreferences;
//   final DateTime startDate;
//   final String location;
//   final String? candidateLocation;
//   final double? radius;
//   final String relocationOptions;

//   JobListing({
//     required this.employer,
//     required this.projectName,
//     required this.jobDescription,
//     required this.industry,
//     required this.employmentType,
//     required this.title,
//     required this.experienceLevel,
//     this.backgroundPreferences,
//     required this.startDate,
//     required this.location,
//     this.candidateLocation,
//     this.radius,
//     required this.relocationOptions,
//   }

// factory JobListing.fromJson(Map<String, dynamic> json) {
// return JobListing(
// id: json['id'] ?? '',
// employer: json['employer'] ?? '',
// projectName: json['projectName'] ?? '',
// jobDescription: json['jobDescription'] ?? '',
// industry: json['industry'] ?? '',
// employmentType: json['employmentType'] ?? '',
// title: json['title'] ?? '',
// experienceLevel: json['experienceLevel'] ?? '',
// backgroundPreferences: json['backgroundPreferences'],
// startDate: json['startDate'] != null
// ? DateTime.parse(json['startDate'])
//     : DateTime.now(),
// location: json['location'] ?? '',
// candidateLocation: json['candidateLocation'],
// radius: json['radius']?.toDouble(),
// relocationOptions: json['relocationOptions'] ?? '',
// isShortlisted: json['isShortlisted'] ?? false,
// createdAt: json['createdAt'] != null
// ? DateTime.parse(json['createdAt'])
//     : DateTime.now(),
// );
// }
//   );

//   // Convert JobListing to JSON for API
//   Map<String, dynamic> toJson() {
//     return {
//       'employer': employer, // Ensure this is handled appropriately
//       'projectName': projectName,
//       'jobDescription': jobDescription,
//       'industry': industry,
//       'employmentType': employmentType,
//       'title': title,
//       'experienceLevel': experienceLevel,
//       'backgroundPreferences': backgroundPreferences,
//       'startDate': startDate.toIso8601String(),
//       'location': location,
//       'candidateLocation': candidateLocation,
//       'radius': radius,
//       'relocationOptions': relocationOptions,
//     };
//   }
// }*/

class JobListing {
  final String id;
  final dynamic employer;
  final String title;
  final String description;
  final List<String> skills;
  final String location;
  final String workType;
  final num budget;
  final String duration;
  final String status;
  final List<AcceptedBy> acceptedBy;
  final DateTime createdAt;
  final int views; // <-- Add this line

  JobListing({
    required this.id,
    required this.employer,
    required this.title,
    required this.description,
    required this.skills,
    required this.location,
    required this.workType,
    required this.budget,
    required this.duration,
    required this.status,
    required this.acceptedBy,
    required this.createdAt,
    this.views = 0, // <-- Add this line
  });

  factory JobListing.fromJson(Map<String, dynamic> json) {
    return JobListing(
      id: json['_id'] ?? json['id'] ?? '',
      employer: json['employer'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      location: json['location'] ?? '',
      workType: json['workType'] ?? 'remote',
      budget: json['budget'] ?? 0,
      duration: json['duration'] ?? '',
      status: json['status'] ?? 'open',
      acceptedBy: (json['acceptedBy'] as List<dynamic>?)
          ?.map((e) => AcceptedBy.fromJson(e))
          .toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      views: json['views'] ?? 0, // <-- Add this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'skills': skills,
      'location': location,
      'workType': workType,
      'budget': budget,
      'duration': duration,
      'status': status,
      // 'employer': employer,
      // 'acceptedBy': acceptedBy.map((e) => e.toJson()).toList(),
      'views': views, // <-- Add this line
    };
  }
}

class AcceptedBy {
  final dynamic jobSeeker; // <-- Change from String to dynamic
  final String status;
  final DateTime acceptedAt;

  AcceptedBy({
    required this.jobSeeker,
    required this.status,
    required this.acceptedAt,
  });

  factory AcceptedBy.fromJson(Map<String, dynamic> json) {
    return AcceptedBy(
      jobSeeker: json['jobSeeker'], // Could be String or Map
      status: json['status'] ?? 'pending',
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobSeeker': jobSeeker is Map ? (jobSeeker['_id'] ?? jobSeeker['id'] ?? '') : jobSeeker,
      'status': status,
      'acceptedAt': acceptedAt.toIso8601String(),
    };
  }
}
