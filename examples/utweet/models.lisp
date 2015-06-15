(in-package :cl-user)
(defpackage utweet.models
  (:use :cl)
  (:export :user
           :user-name
           :user-email
           :user-password
           :user-avatar-url)
  (:export :subscription
           :subscription-follower
           :subscription-followed)
  (:export :tweet
           :tweet-author
           :tweet-text
           :tweet-timestamp)
  (:export :find-user
           :register-user
           :followers
           :following
           :tweet
           :user-timeline
           :user-tweets
           :follow))
(in-package :utweet.models)

;;; Models

(defclass user ()
  ((name :accessor user-name
              :initarg :name
              :type string)
   (email :accessor user-email
          :initarg :email
          :type string)
   (password :accessor user-password
             :initarg :password
             :type string)
   (avatar-url :accessor user-avatar-url
               :initarg :avatar-url
               :type string)))

(defclass subscription ()
  ((follower :reader subscription-follower
             :initarg :follower
             :type email
             :documentation "The follower's email.")
   (followed :reader subscription-followed
             :initarg :followed
             :type string
             :documentation "The followed's email.")))

(defclass tweet ()
  ((author :reader tweet-author
           :initarg :author
           :type string
           :documentation "The author's email.")
   (text :reader tweet-text
         :initarg :text
         :type string)
   (timestamp :reader tweet-timestamp
              :initarg :timestamp
              :initform (local-time:now))))

;;; Storage

(defparameter *users* (make-hash-table :test #'equal))

(defparameter *subscriptions* (list))

(defparameter *tweets* (list))

;;; Functions

(defun find-user (email)
  "Find a user by email address."
  (gethash email *users*))

(defun register-user (&key name email password)
  "Register the user and hash their password."
  (setf (gethash email *users*)
        (make-instance 'user
                       :name name
                       :email email
                       :password (cl-pass:hash password)
                       :avatar-url (avatar-api:gravatar email 120))))

(defun followers (user)
  "List of users that follow the user."
  (mapcar #'(lambda (sub)
              (find-user (subscription-follower sub)))
          (remove-if-not #'(lambda (sub)
                             (string= (subscription-followed sub)
                                      (user-email user)))
                         *subscriptions*)))

(defun following (user)
  "List of users the user follows."
  (mapcar #'(lambda (sub)
              (find-user (subscription-followed sub)))
          (remove-if-not #'(lambda (sub)
                             (string= (subscription-follower sub)
                                      (user-email user)))
                         *subscriptions*)))

(defun tweet (author text)
  (push (make-instance 'tweet
                       :author (user-email author)
                       :text text)
        *tweets*))

(defun sort-tweets (tweets)
  "Given a list of tweets, sort them so the newest are first."
  (sort tweets
        #'(lambda (tweet-a tweet-b)
            (local-time:timestamp>= (tweet-timestamp tweet-a)
                                    (tweet-timestamp tweet-b)))))

(defun user-timeline (user)
  "Find the tweets for this user's timeline."
  (sort-tweets (remove-if-not #'(lambda (tweet)
                                  (member (tweet-author tweet)
                                          (following user)
                                          :test #'equal))
                              *tweets*)))

(defun user-tweets (user)
  "Return a user's tweets, sorted through time"
  (sort-tweets (remove-if-not #'(lambda (tweet)
                                  (string= (tweet-author tweet)
                                           (user-email user)))
                              *tweets*)))

(defun follow (follower followed)
  "Follow a user."
  (push (make-instance 'subscription
                       :follower (user-email follower)
                       :followed (user-email followed))
        *subscriptions*))

;;; Create some example data

#|
(let ((eudox (register-user "eudoxia" "eudoxia" "black.linen99@gmail.com" "pass"))
      (john  (register-user "john" "John Doe" "jdoe@initech.com" "test"))
      (jane  (register-user "jane" "Jane Doe" "jane.doe@initech.com" "test")))
  ;; Make eudoxia follow both
  (follow eudox john)
  (follow eudox jane)
  ;; Now write some test tweets
  (tweet john "Test message BEEP")
  (tweet jane "Test message BOOP")
  (tweet john "BEEP BOOP feed me followers"))
|#
