demo app to build & deploy pontoon to k8s

gitlab-ci file attached

for hiding some passwords etc plugin `helm secrets` can be used

I have some doubts about `/app/media/projects/` folder, it can be needed by all runned pods. In this case `rbd` or NFS can be mounted to different pods.
