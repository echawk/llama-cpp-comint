;;; llama-cpp-mode.el -- Run a GGML model via llama.cpp in a comint process.

;;; Commentary:

;; llama-cpp-mode.el is a comint mode for Emacs that allows you to use
;; llama.cpp and the assosciated GGML models as an inferior process that
;; you can interact with.  Currently is very spartan in its configuration,
;; but is sufficient for most uses, and will be improved in the future.

;;; Code:

(require 'comint)

(defgroup llama-cpp-comint nil
  "Run a llama.cpp process in a comint buffer."
  :group 'languages)

(defcustom llama-cpp-model-alist
  '(("LLaMA-v2" "/opt/llama.cpp/build/bin/main" "/opt/model/llmama-model.bin")
    ("GPT2" "/opt/llama.cpp/build/bin/main" "/opt/model/gpt2-model.bin"))
  "Alist mapping a human readable name to a llama.cpp executable and a ggml model binary."
  :type '(alist)
  :group 'llama-cpp-comint)

(defcustom llama-cpp-num-cpus 4
  "Number of CPUS to use with `llama-cpp-main-path`."
  :type 'number
  :group 'llama-cpp-comint)

(defcustom llama-cpp-buffer-name "*LLaMA-cpp*"
  "Name of the buffer to use for the `run-llama-cpp` comint instance."
  :type 'string
  :group 'llama-cpp-comint)

(defcustom llama-cpp-queries
  '("Can you explain this code block?"
    "Can you summarize the following text?")
  "List of queries that can be used with `llama-cpp-query-region`."
  :type '(string)
  :group 'llama-cpp-comint)

(defun llama-cpp-get-args (model-path)
  "Return the list of arguments for the selected model based on the MODEL-PATH."
  (concat
   " -t " (format "%s" llama-cpp-num-cpus)
   " -m " model-path
   " -i "
   " -ins "
   " --multiline-input"))

(defun llama-cpp-running-p ()
  "Return nil if the llama-cpp comint buffer isn't running."
  (let* ((buffer     (get-buffer-create llama-cpp-buffer-name))
         (proc-alive (comint-check-proc buffer)))
    proc-alive))

(defun llama-cpp-make-comint-buff (program args)
  "Make a comint buffer with PROGRAM with ARGS."
  (set-buffer (apply (function make-comint)
                     "LLaMA-cpp" program nil args)))

(defun llama-cpp-query-region ()
  "Run a query on the currently selected region."
  (interactive)
  (let ((buff
         (concat
          (concat (completing-read "Enter a Query: " llama-cpp-queries)
                  "\n\n"
                  (buffer-substring-no-properties (region-beginning)
                                                  (region-end))
                  "\\\n"))))
    ;; Start up llama-cpp comint buffer if not already running.
    (unless (llama-cpp-running-p)
      (run-llama-cpp))
    (with-current-buffer llama-cpp-buffer-name
      (goto-char (point-max))
      (comint-send-string llama-cpp-buffer-name buff)
      (let ((pos (point)))
        (comint-send-input)
        (save-excursion
          (goto-char pos)
          (insert buff))))
    (display-buffer llama-cpp-buffer-name)))

(defun run-llama-cpp ()
  "Run an inferior instance of a selected GGML model inside of Emacs."
  (interactive)
  (let* (
         (model-str            (completing-read "Choose a Model: " (mapcar 'car llama-cpp-model-alist)))
         (model-info           (cdr (assoc model-str llama-cpp-model-alist)))
         (llama-cpp-program    (car model-info))
         (llama-cpp-model-path (car (cdr model-info)))

         (alive                (comint-check-proc llama-cpp-buffer-name))
         (args                 (split-string-shell-command (llama-cpp-get-args llama-cpp-model-path))))
    (unless alive
      (llama-cpp-make-comint-buff llama-cpp-program args))
    (display-buffer llama-cpp-buffer-name)))

(define-derived-mode llama-cpp-comint-mode comint-mode "Inferior LLaMA-cpp"
  "Major mode for interacting with an inferior LLaMA.cpp process."
  :group 'llama-cpp-comint)

(provide 'llama-cpp-comint)
;;; llama-cpp-comint.el ends here
