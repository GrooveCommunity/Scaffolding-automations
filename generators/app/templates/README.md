# <%= name %>

This project was generated with [generator-lambda-node]()

> :warning: **Attention**: Remember to create the repository with the name "<%= name %>" and define the necessary secrets as you can see [here](#define-secrets-to-aws).
## Firsts steps

1. Create the repository "<%= name %>"
2. Commit this files with ```git commit -m "your first commit message"```
3. git push -u origin HEAD

## Define secrets to AWS

You need to set these secrets for everything to work as expected to find more information read the [documentation about secrets](https://docs.github.com/pt/actions/reference/encrypted-secrets).

```yaml
aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
aws-region: ${{ secrets.AWS_REGION }}
```

Find the value of these secrets [here](https://docs.aws.amazon.com/pt_br/general/latest/gr/aws-sec-cred-types.html).
