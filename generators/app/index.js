'use strict';
const Generator = require('yeoman-generator');
const chalk = require('chalk');
const yosay = require('yosay');
const path = require('path');

module.exports = class extends Generator {
  prompting() {
    this.log(
      yosay(
        `${chalk.blue('Welcome')} we will help you to set up and configure `+
        `${chalk.red('lambda function')} using ` +
        `${chalk.green('Terraform')} and ${chalk.green('Gh actions')}`
      )
    );

    const lambdaQuestions = () => {
      const questions = [
        {
          type: 'input',
          name: 'name',
          message: 'Function name:',
          validate(response) {
            return response.indexOf(' ') === -1 || 'Function name can\'t contains space';
          },
        },
        {
          type: 'input',
          name: 'description',
          message: 'Description:',
        },
        {
          type: 'list',
          name: 'method',
          message: 'method:',
          choices: [
            'POST',
            'GET',
          ],
        },
        {
          type: 'input',
          name: 'path',
          message: 'url path:',
        },
        {
          type: 'confirm',
          name: 'more',
          message: 'Create another handler:',
          default: false,
        },
      ];

      return this
        .prompt(questions)
        .then(
          ({ more, ...lambda }) => {
            this.props.lambdaFunctions = Array.isArray(this.props.lambdaFunctions)
              ? [...this.props.lambdaFunctions, lambda]
              : [lambda];
            return more;
          },
        )
        .then(
          more => more ? lambdaQuestions() : this.props,
        );
    }

    const allQuestions = () => {
      const questions = [
        {
          type: 'input',
          name: 'name',
          message: 'Project name:',
          validate(response) {
            return response.indexOf(' ') === -1 || 'Project name can\'t contains space';
          },
        },
        {
          type: 'input',
          name: 'owner',
          message: 'Organization or user owner:',
        },
        {
          type: 'input',
          name: 'description',
          message: 'Description:',
        },
      ];

      return this
        .prompt(questions)
        .then(
          props => this.props = props,
        )
        .finally(
          () => lambdaQuestions(),
        );

    }

    return allQuestions();
  }

  writing() {
    const configFile = path.resolve(__dirname, '..', '..', '.yo-rc.json');
    const config = this.fs.readJSON(configFile);

    const templateFunction = (name, method, path, description) => [
      `    ${name} = {`,
      `      description = "${description}"`,
      `      method = "${method}"`,
      `      path = "${path}"`,
      '    }',
    ].join('\n');

    this.destinationRoot(this.props.name);

    const functionsTemplate = this.props.lambdaFunctions
      .map(
        ({ name, method, path, description }) => {
          this.fs
            .copy(
              this.templatePath('src/index.ts'),
              this.destinationPath(`src/${name}.ts`),
            );

          return templateFunction(name, method, path, description);
        },
      );

    const functions = `{\n${functionsTemplate.join('\n')}\n  }`;

    config.files
      .forEach(
        file => this.fs
          .copyTpl(
            this.templatePath(file),
            this.destinationPath(file),
            { ...this.props, functions },
          )
      );
  }

  install() {
    this.installDependencies();
  }

  end() {
    this.spawnCommandSync('git', ['init']);
  }
};
