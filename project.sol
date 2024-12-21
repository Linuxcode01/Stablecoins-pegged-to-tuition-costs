// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LearnToEarn {
    address public owner;
    address public stablecoin;

    struct Course {
        string title;
        string description;
        uint256 cost;
        address creator;
        uint256 enrolledCount;
    }

    struct Enrollment {
        uint256 courseId;
        address student;
        bool completed;
    }

    Course[] public courses;
    mapping(address => uint256[]) public studentEnrollments;
    mapping(uint256 => mapping(address => Enrollment)) public courseEnrollments;

    event CourseCreated(uint256 indexed courseId, string title, uint256 cost, address creator);
    event Enrolled(uint256 indexed courseId, address indexed student);
    event CourseCompleted(uint256 indexed courseId, address indexed student);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(address _stablecoin) {
        owner = msg.sender;
        stablecoin = _stablecoin;
    }

    function createCourse(string memory _title, string memory _description, uint256 _cost) public {
        require(_cost > 0, "Cost must be greater than zero");
        
        courses.push(Course({
            title: _title,
            description: _description,
            cost: _cost,
            creator: msg.sender,
            enrolledCount: 0
        }));

        emit CourseCreated(courses.length - 1, _title, _cost, msg.sender);
    }

    function enroll(uint256 _courseId) public {
        require(_courseId < courses.length, "Course does not exist");

        Course storage course = courses[_courseId];
        require(IERC20(stablecoin).transferFrom(msg.sender, course.creator, course.cost), "Payment failed");

        course.enrolledCount += 1;
        studentEnrollments[msg.sender].push(_courseId);
        courseEnrollments[_courseId][msg.sender] = Enrollment({
            courseId: _courseId,
            student: msg.sender,
            completed: false
        });

        emit Enrolled(_courseId, msg.sender);
    }

    function markCourseComplete(uint256 _courseId, address _student) public {
        require(_courseId < courses.length, "Course does not exist");
        require(courses[_courseId].creator == msg.sender, "Only the course creator can mark completion");

        Enrollment storage enrollment = courseEnrollments[_courseId][_student];
        require(!enrollment.completed, "Course already completed");
        require(enrollment.student == _student, "Invalid enrollment");

        enrollment.completed = true;

        emit CourseCompleted(_courseId, _student);
    }

    function getStudentEnrollments(address _student) public view returns (uint256[] memory) {
        return studentEnrollments[_student];
    }

    function getCourseCount() public view returns (uint256) {
        return courses.length;
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
